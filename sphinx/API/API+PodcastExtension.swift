//
//  APIPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreData
import ObjectMapper

extension API {
    
    func getContentFeed(
        url: String,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil,
        callback: @escaping ContentFeedCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { response in
            if let data = response.data {
                callback(JSON(data))
            } else {
                errorCallback()
            }
        }
    }
    
    
    func getPodcastInfo(podcastId: Int, callback: @escaping PodcastInfoCallback, errorCallback: @escaping EmptyCallback) {
        let url = API.getUrl(route: "https://tribes.sphinx.chat/podcast?id=\(podcastId)")
        let tribeRequest : URLRequest? = createRequest(url, bodyParams: nil, method: "GET")
        
        guard let request = tribeRequest else {
            errorCallback()
            return
        }
        
        //NEEDS TO BE CHANGED
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(JSON(json))
                } else {
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func streamSats(params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/stream", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func updateChat(chatId: Int, params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/chats/\(chatId)", params: params as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getAllContentFeedStatuses(
        url: String,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil,
        callback: @escaping AllContentFeedStatusCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        /*
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
            errorCallback()
            return
        }
         */
        
        var status_array = [[String:Any]]()
        var status1_json = [String:Any]()
        status1_json["chat_id"] = "abc456"
        status1_json["feed_id"] = "xyz89"
        status_array.append(status1_json)
        if let status1 = Mapper<ContentFeedStatus>().mapArray(JSONObject: status_array){
            callback(status1)
        }
        else{
            errorCallback()
        }
        /*
        AF.request(request).responseJSON { response in
            if let data = response.data {
                callback(JSON(data))
            } else {
                errorCallback()
            }
        }
        */
    }
    
    func saveContentFeedStatusesToRemote(
        params: [[String: Any]],
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        for paramSet in params{
            guard let request = getURLRequest(route: "TODO: Set this to the correct url", params: paramSet as NSDictionary?, method: "PUT") else {
                errorCallback()
                return
            }
            
            sphinxRequest(request) { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? NSDictionary {
                        if let success = json["success"] as? Bool, success {
                            callback()
                            return
                        }
                    }
                    errorCallback()
                case .failure(_):
                    errorCallback()
                }
            }
        }
        
    }
}
