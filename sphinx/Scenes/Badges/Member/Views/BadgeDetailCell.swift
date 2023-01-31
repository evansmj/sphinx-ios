//
//  MemberBadgeDetailCell.swift
//  sphinx
//
//  Created by James Carucci on 1/31/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class BadgeDetailCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeTitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(badge:Badge){
        badgeTitleLabel.text = badge.name ?? ""
        badgeImageView.sd_setImage(with: URL(string: badge.icon_url ?? ""))
    }
    
}

// MARK: - Static Properties
extension BadgeDetailCell {
    static let reuseID = "BadgeDetailCell"
    
    static let nib: UINib = {
        UINib(nibName: "BadgeDetailCell", bundle: nil)
    }()
    
}
