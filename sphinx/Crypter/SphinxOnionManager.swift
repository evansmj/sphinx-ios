//
//  SphinxOnionManager.swift
//  
//
//  Created by James Carucci on 11/8/23.
//

import Foundation
import CocoaMQTT
import ObjectMapper

// Define a struct to represent the JSON structure
struct OnionConnectionData: Mappable {
    var scid: String?
    var serverPubkey: String?
    var myPubkey: String?
    var vc: UIViewController! = nil

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        scid <- map["scid"]
        serverPubkey <- map["server_pubkey"]
    }
}


class SphinxOnionManager : NSObject {
    class var sharedInstance : SphinxOnionManager {
        struct Static {
            static let instance = SphinxOnionManager()
        }
        return Static.instance
    }
    
    var pendingContact : UserContact? = nil
    var currentServer : Server? = nil
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var shouldPostUpdates : Bool = false
    let server_IP = "54.164.163.153"
    let server_PORT = 1883
    //let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"//TODO: stop using this in favor of one generated by user, backed up by hand and stored in secure memory
    let network = "regtest"
    var vc: UIViewController! = nil
    var mqtt: CocoaMQTT! = nil
    
    func getAccountSeed(mnemonic:String)->String?{
        do{
            let seed = try mnemonicToSeed(mnemonic: mnemonic)
            return seed
        }
        catch{
            print("error in getAccountSeed")
            return nil
        }
    }
    
    func generateMnemonic()->String?{
        var result : String? = nil
        do {
            result = try mnemonicFromEntropy(entropy: Data.randomBytes(length: 16).hexString)
        }
        catch let error{
            print("error getting seed\(error)")
        }
        return result
    }
    
    func getAccountXpub(seed:String) -> String?  {
        do{
            let xpub = try xpubFromSeed(seed: seed, time: getTimestampInMilliseconds(), network: network)
            return xpub
        }
        catch{
            return nil
        }
    }
    
    func getAccountOnlyKeysendPubkey(seed:String)->String?{
        do{
            let pubkey = try pubkeyFromSeed(seed: seed, idx: 0, time: getTimestampInMilliseconds(), network: network)
            return pubkey
        }
        catch{
            return nil
        }
    }
    
    func getTimestampInMilliseconds()->String{
        let nowSeconds = Date().timeIntervalSince1970
        let nowMilliseconds = Int64(nowSeconds * 1000)
        let nowMsString = String(nowMilliseconds)
        return nowMsString
    }
    
    func connectToBroker(seed:String,xpub:String)->Bool{
        if mqtt?.connState == .connected || mqtt?.connState == .connecting {
            showSuccessWithMessage("MQTT already connected or connecting")
            return true
        }
        do{
            let now = getTimestampInMilliseconds()
            let sig = try rootSignMs(seed: seed, time: now, network: network)
            
            mqtt = CocoaMQTT(clientID: xpub,host: server_IP ,port:  UInt16(server_PORT))
            mqtt.username = now
            mqtt.password = sig
            
            let success = mqtt.connect()
            print("mqtt.connect success:\(success)")
            return success
        }
        catch{
            return false
        }
    }
    
    func subscribeAndPublishTopics(pubkey:String,idx:Int){
        self.mqtt.subscribe([
            ("\(pubkey)/\(idx)/res/#", CocoaMQTTQoS.qos1)
        ])
        
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/register",
                payload: []
            )
        )
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/pubkey",
                payload: []
            )
        )
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/balance",
                payload: []
            )
        )
    }
    
    
    func createAccount(mnemonic:String)->Bool{
        do{
            //1. Generate Seed -> Display to screen the mnemonic for backup???
            guard let seed = getAccountSeed(mnemonic: mnemonic) else{
                //possibly send error message?
                return false
            }
            //2. Create the 0th pubkey
            guard let pubkey = getAccountOnlyKeysendPubkey(seed: seed),
                  let my_xpub = getAccountXpub(seed: seed) else{
                  return false
            }
            //3. Connect to server/broker
            let success = connectToBroker(seed:seed,xpub: my_xpub)
            
            //4. Subscribe to relevant topics based on OK key
            let idx = 0
            if success{
                mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                    self.processMqttMessages(message: receivedMessage)
                }
                
                //subscribe to relevant topics
                mqtt.didConnectAck = { _, _ in
                    //self.showSuccessWithMessage("MQTT connected")
                    print("SphinxOnionManager: MQTT Connected")
                    print("mqtt.didConnectAck")
                    self.subscribeAndPublishTopics(pubkey: pubkey, idx: idx)
                }
            }
            return success
        }
        catch{
            print("error connecting to mqtt broker")
            return false
        }
       
    }
    
    func processRegisterTopicResponse(registerMessage:CocoaMQTTMessage){
        let payloadData = Data(registerMessage.payload)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("MQTT Topic:\(registerMessage.topic) with Payload as String: \(payloadString)")
            if let retrievedCredentials = Mapper<OnionConnectionData>().map(JSONString: payloadString){
                print("Onion Credentials register over MQTT:\(retrievedCredentials)")
                //5. Store my credentials (SCID, serverPubkey, myPubkey)
                if let scid = retrievedCredentials.scid{
                    createSelfContact(scid: scid)
                }
                saveLSPServerData(retrievedCredentials: retrievedCredentials)
            }
        } else {
            print("MQTT Unable to convert payload to a string")
        }
    }
    
    func processBalanceUpdateMessage(balanceUpdateMessage:CocoaMQTTMessage){
        let payloadData = Data(balanceUpdateMessage.payload)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("MQTT Topic:\(balanceUpdateMessage.topic) with Payload as String: \(payloadString)")
            (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .onBalanceDidChange, object: nil, userInfo: ["balance" : payloadString])) : ()
        }
    }
    
    func processMqttMessages(message:CocoaMQTTMessage){
        let tops = message.topic.split(separator: "/")
        if tops.count < 4{
            return
        }
        let topic = tops[3]
        switch(topic){
        case "register":
            print("processing register topic!")
            processRegisterTopicResponse(registerMessage: message)
            break
        case "balance":
            print("processing balance topic!")
            processBalanceUpdateMessage(balanceUpdateMessage: message)
            break
        default:
            print("topic not in list:\(topic)")
            break
        }
    }
    
    func showSuccessWithMessage(_ message: String) {
        self.newMessageBubbleHelper.showGenericMessageView(
            text: message,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.PrimaryGreen,
            backAlpha: 1.0
        )
    }
}

extension SphinxOnionManager{//Sign Up UI Related:
    func chooseImportOrGenerateSeed(){
        let requestEnteredMneumonicCallback: (() -> ()) = {
            self.importSeedPhrase()
        }
        
        let generateSeedCallback: (() -> ()) = {
            guard let mneomnic = self.generateMnemonic(),
                  let vc = self.vc as? NewUserSignupFormViewController else{
                return
            }
            self.showMnemonicToUser(mnemonic: mneomnic, callback: {
                self.createAccount(mnemonic: mneomnic)
                vc.signup_v2_with_test_server()
            })
        }
        
        AlertHelper.showTwoOptionsAlert(
            title: "profile.mnemonic-generate-or-import-title".localized,
            message: "profile.mnemonic-generate-or-import-prompt".localized,
            confirmButtonTitle: "profile.mnemonic-generate-prompt".localized,
            cancelButtonTitle: "profile.mnemonic-import-prompt".localized,
            confirm: generateSeedCallback,
            cancel: requestEnteredMneumonicCallback
        )
    }
    
    func importSeedPhrase(){
        if let vc = self.vc as? ImportSeedViewDelegate {
            vc.showImportSeedView()
        }
    }
    
    func showMnemonicToUser(mnemonic: String, callback: @escaping () -> ()) {
        guard let vc = vc else {
            callback()
            return
        }
        
        let copyAction = UIAlertAction(
            title: "Copy",
            style: .default,
            handler: { _ in
                ClipboardHelper.copyToClipboard(text: mnemonic, message: "profile.mnemonic-copied".localized)
                callback()
            }
        )
        
        AlertHelper.showAlert(
            title: "profile.store-mnemonic".localized,
            message: mnemonic,
            on: vc,
            additionAlertAction: copyAction,
            completion: {
                callback()
            }
        )
    }
    
}

extension SphinxOnionManager{//contacts related
    func saveLSPServerData(retrievedCredentials:OnionConnectionData){
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        let server = Server(context: managedContext)

        server.pubKey = retrievedCredentials.serverPubkey
        server.ip = self.server_IP
        (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .onMQTTConnectionStatusChanged, object: nil, userInfo: ["server" : server])) : ()
        self.currentServer = server
        managedContext.saveContext()
    }
    
    func createSelfContact(scid:String){
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        self.pendingContact = UserContact(context: managedContext)
        self.pendingContact?.scid = scid
        self.pendingContact?.isOwner = true
        self.pendingContact?.index = 0
        managedContext.saveContext()
    }
}
