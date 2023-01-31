//
//  MemberBadgeDetailVM.swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class MemberBadgeDetailVM : NSObject {
    var vc: MemberBadgeDetailVC
    var tableView: UITableView
    var presentationContext : MemberBadgeDetailPresentationContext
    var badgeDetailExpansionState : Bool = false
    var badges : [Badge] = []
    
    init(vc: MemberBadgeDetailVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
        self.presentationContext = vc.presentationContext
        //TODO: replace with API call
        let badge = Badge()
        badge.name = "Early Adopter"
        badge.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        let badge2 = Badge()
        badge2.name = "Early Adopter2"
        badge2.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        self.badges = [
            badge,
            badge2
        ]
    }
    
    func configTable(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberDetailTableViewCell.reuseID)
        tableView.register(UINib(nibName: "BadgeDetailCell", bundle: nil), forCellReuseIdentifier: BadgeDetailCell.reuseID)
        
        tableView.reloadData()
    }
    
    func getCellTypeOrder() -> [MemberBadgeDetailCellType] {
        var result = [MemberBadgeDetailCellType]()
        switch(presentationContext){
        case .member:
            result = [
                .posts,
                .contributions,
                .earnings
            ]
            break
        case .admin:
            result = [
                .badges,
                .posts,
                .contributions,
                .earnings
            ]
            break
        }
        if(badgeDetailExpansionState == true){
            for badge in badges{
                result.insert(.details, at: 1)
            }
        }
        
        return result
    }
    
}


extension MemberBadgeDetailVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getCellTypeOrder().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellTypes = getCellTypeOrder()
        let cellType = cellTypes[indexPath.row]
        if(cellType == .details){
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BadgeDetailCell.reuseID,
                for: indexPath
            ) as! BadgeDetailCell
            cell.configCell(badge: badges[indexPath.row - 1])
            
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberDetailTableViewCell.reuseID,
                for: indexPath
            ) as! MemberDetailTableViewCell
            cell.configureCell(type: getCellTypeOrder()[indexPath.row])
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            (badgeDetailExpansionState == false) ? vc.expandBadgeDetail() : vc.dismissBadgeDetails()
            badgeDetailExpansionState = !badgeDetailExpansionState
            tableView.reloadData()
        }
    }
    
    
}
