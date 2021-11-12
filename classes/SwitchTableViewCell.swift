//
//  SwitchTableViewCell.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 28/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

protocol SwitchTableViewCellDelegate {
  func didChange(setting: Setting.Notification, to isOn: Bool)
}

class SwitchTableViewCell: UITableViewCell {
  
  public static let identifier = "SwitchTableViewCell"
  
  @IBOutlet weak var cellLabel: UILabel!
  @IBOutlet weak var cellSwitch: UISwitch!
  
  var setting: Setting.Notification?
  var delegate: SwitchTableViewCellDelegate?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  @IBAction func didSwitch(_ sender: Any) {
    if let setting = setting {
      delegate?.didChange(setting: setting, to: cellSwitch.isOn)
    }
  }
}
