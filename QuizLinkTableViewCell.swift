//
//  QuizLinkTableViewCell.swift
//  tourismtemplate
//
//  Created by G0yter on 07.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

class QuizLinkTableViewCell: UITableViewCell {
    
    @IBOutlet weak var quizImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var containerView: UIStackView!
    
    
    public static let identifier = "QuizLinkTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell() {
        containerView.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
        titleLabel.font = UIFont.systemFont(ofSize: 19)
        titleLabel.textColor = Globals.Color.textColor
        subtitleLabel.font = UIFont.systemFont(ofSize: 17)
        subtitleLabel.textColor = Globals.Color.textColor
        subtitleLabel.numberOfLines = 0
        
        quizImage?.tintColor = Globals.Color.textColor
    }
    
}
