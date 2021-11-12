//
//  LoadingCollectionViewCell.swift
//  tourismtemplate
//
//  Created by Raphael Seher on 12.12.17.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

class LoadingCollectionViewCell: UICollectionViewCell {
  
  static let identifier = "LoadingCollectionViewCell"
  
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  func setup() {
    loadingIndicator.startAnimating()
  }
}
