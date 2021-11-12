//
//  GuideCollectionViewCell.swift
//  tourismtemplate
//
//  Created by G0yter on 11.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

class GuideCollectionViewCell: UICollectionViewCell {
    static let identifier = "GuideCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
      imageView.isHidden = true
      imageView.image = nil
    }
    
    func configureCell(item: GuideItem) {
      
      if let image = item.image {
          imageView.isHidden = false
          imageView.image = image
      } else {
          imageView.isHidden = false
          imageView.image = nil
          imageView.backgroundColor = Globals.Color.primaryColor
      }
      
      titleLabel.text = item.title
    }
}
