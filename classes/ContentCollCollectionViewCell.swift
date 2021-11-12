//
//  ContentCollCollectionViewCell.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 19/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

class ContentCollectionViewCell: UICollectionViewCell {
  static let identifier = "ContentCollectionViewCell"
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var topTipImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func prepareForReuse() {
    topTipImageView.isHidden = true
    imageView.image = nil
  }
  
  func configureCell(content: XMMContent) {
    if content.customMeta["top-tip"] != nil {
      topTipImageView.isHidden = false
      topTipImageView.image =
        UIImage(named: NSLocalizedString("contencollectionview.banner.image",
                                         comment: "Top tip banner image"))
    } else {
      topTipImageView.isHidden = true
    }
    
    if let imageUrl = content.imagePublicUrl {
      imageView.sd_setImage(with: URL(string: imageUrl),
                            placeholderImage: Globals.Image.placeholder)
    }
    
    titleLabel.text = content.title
  }
  
}
