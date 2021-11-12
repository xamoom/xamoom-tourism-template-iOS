//
//  ContentLinkTableViewCell.swift
//  tourismtemplate
//
//  Created by G0yter on 14.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

class ContentLinkTableViewCell: UITableViewCell {

    public static let identifier = "ContentLinkCell"
    
    @IBOutlet weak var contentImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(content: XMMContent) {
        if let titleText = content.title {
            titleLabel.text = titleText
            titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        }
        
        descriptionLabel.text = content.contentDescription
        descriptionLabel.font = UIFont.systemFont(ofSize: 10)
        descriptionLabel.numberOfLines = 3
        
        if let imageUrl = content.imagePublicUrl {
            contentImage.sd_setImage(with: URL(string: imageUrl),
                                placeholderImage: Bundle.main.smallIcon)
        } else {
            contentImage.image = Bundle.main.smallIcon
        }
        self.selectionStyle = .none
    }
    
    override func prepareForReuse() {
            super.prepareForReuse()
            contentImage.image = nil
        }

    
}
