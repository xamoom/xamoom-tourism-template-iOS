//
//  NotificationView.swift
//  kollitsch-art
//
//  Created by Raphael Seher on 06/03/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import Foundation

class NotificationView: UIView {
  
  @IBOutlet weak var messageLabel: UILabel!
  
  var message : String? {
    didSet {
      messageLabel.text = message
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupGestureRecognizer()
  }
  
  func setupGestureRecognizer() {
    let tapGesture = UITapGestureRecognizer(target: self,
                                            action: #selector(didTap(recognizer:)))
    self.addGestureRecognizer(tapGesture)
  }

  override func didMoveToWindow() {
    guard let superView = self.superview else {
      return
    }
    
    self.frame.size.width = superView.frame.width
    
    let timer = Timer.scheduledTimer(timeInterval: 5.0,
                                     target: self,
                                     selector: #selector(remove),
                                     userInfo: nil,
                                     repeats: false)
  }
  
  @objc func didTap(recognizer: UIGestureRecognizer) {
    remove()
  }
  
  @objc func remove() {
    self.removeFromSuperview()
  }
}
