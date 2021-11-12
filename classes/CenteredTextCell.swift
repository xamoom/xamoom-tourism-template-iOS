//
//  CenteredTextCell.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 07.09.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

class CenteredTextCell: UITableViewCell {
    @IBOutlet weak var cellTextLabel: UILabel!
    @IBOutlet weak var cellContainer: UIView!
    
    public static let identifier = "CenteredTextCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
