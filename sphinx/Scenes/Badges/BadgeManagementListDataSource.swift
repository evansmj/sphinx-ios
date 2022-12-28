//
//  BadgeManagementListDataSource.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit


class BadgeManagementListDataSource : NSObject{
    private var badges : [Badge]
    var vc : BadgeManagementListVC
    
    init(badges: [Badge] = [Badge](),vc:BadgeManagementListVC) {
        self.badges = badges
        self.vc = vc
    }
    
    func setupDataSource(){
        vc.badgeTableView.delegate = self
        vc.badgeTableView.dataSource = self
        fetchBadges()
    }
    
    func fetchBadges(){
        //TODO: Add call to service here
        
        //Fake data here:
        let n_badges = 10
        for i in 0...n_badges{
            let new_badge = Badge()
            new_badge.name = "my_badge\(i)"
            self.badges.append(new_badge)
        }
        self.vc.badgeTableView.reloadData()
    }
}

extension BadgeManagementListDataSource : UITableViewDelegate,UITableViewDataSource{
    
    func getNBadges()->Int{
        return badges.count
    }
    
    func getBadge(index:Int)->Badge{
        return badges[index]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNBadges()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: cell.frame)
        let badge = getBadge(index: indexPath.row)
        label.text = badge.name
        cell.addSubview(label)
        return cell
    }
    
}
