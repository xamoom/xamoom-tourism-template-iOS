//
//  SubtitleTableViewCell.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 18.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {

    public static let identifier = "SubtitleTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isUserInteractionEnabled = false
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        subtitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        subtitleLabel.numberOfLines = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
