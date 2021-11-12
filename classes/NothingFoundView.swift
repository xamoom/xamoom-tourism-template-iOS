//
//  NothingFoundView.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 12/05/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

class NothingFoundView: UIView {
  
  @IBOutlet weak var errorLabel: UILabel!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    errorLabel.text = nil
    
    let views = Bundle.main.loadNibNamed("NothingFoundView", owner: nil, options: nil)
    if let view = views?.first as? NothingFoundView {
      view.frame = frame
      addSubview(view)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
}
