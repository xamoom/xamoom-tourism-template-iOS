//
//  TextCell.swift
//  tourismtemplate
//
//  Created by G0yter on 07.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

class TextCell: UITableViewCell {
    
    @IBOutlet weak var cellTextLabel: UILabel!
    @IBOutlet weak var labelContainer: UIView!
    
    
    public static let identifier = "TextTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(forType cellType: ScoreDisplayType) {
        cellTextLabel.numberOfLines = 0
        if cellType == .title {
            cellTextLabel.font = UIFont.boldSystemFont(ofSize: 20)
        } else if cellType == .quizField {
            cellTextLabel.font = UIFont.systemFont(ofSize: 30)
            cellTextLabel.textColor = Globals.Color.textColor
            labelContainer.backgroundColor = UIColor(patternImage: UIImage(named: "background_image")!)
        } else if cellType == .text {
            cellTextLabel.font = UIFont.systemFont(ofSize: 17)
        } else {
            print("Incorrect cell Type")
        }
    }
}
