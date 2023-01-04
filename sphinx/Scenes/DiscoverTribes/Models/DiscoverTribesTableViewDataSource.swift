//
//  DiscoverTribesTableViewDataSource.swift
//  sphinx
//
//  Created by James Carucci on 1/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


class DiscoverTribeTableViewDataSource : NSObject{
    var tableView : UITableView
    var vc : DiscoverTribesWebViewController
    
    init(tableView:UITableView,vc:DiscoverTribesWebViewController){
        self.vc = vc
        self.tableView = tableView
    }
    
    func fetchTribeData(){
        API.sharedInstance.getAllTribes(callback: { allTribes in
            let topTribes = self.filterTribes(allTribes: allTribes)
        }, errorCallback: {
            //completion()
        })
    }
    
    func filterTribes(allTribes:[Any])->[Any]{
        let tribesLimit = 50
        var result = Array(allTribes[0..<min(tribesLimit,allTribes.count)])
        return result
    }
    
}


extension DiscoverTribeTableViewDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
        label.text = "Hi"
        cell.addSubview(label)
        return cell
    }
    
    
}

extension DiscoverTribeTableViewDataSource : UITableViewDelegate{
    
}

