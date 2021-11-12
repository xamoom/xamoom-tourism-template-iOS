//
//  FilterTableViewCell.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 27/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

protocol FilterTableViewCellDelegate {
  func didAddFilter(tag: String)
  func didRemoveFilter(tag: String)
}

class FilterTableViewCell: UITableViewCell {
  public static let identifier = "FilterTableViewCell"
  
  @IBOutlet weak var filterNameLabel: UILabel!
  @IBOutlet weak var enableSwitch: UISwitch!
  
  var delegate: FilterTableViewCellDelegate?
  var filterTag: String?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  @IBAction func didSwitch(_ sender: Any) {
    guard let filterTag = filterTag else {
      return
    }
    
    if enableSwitch.isOn {
      delegate?.didAddFilter(tag: filterTag)
    } else {
      delegate?.didRemoveFilter(tag: filterTag)
    }
  }
}
