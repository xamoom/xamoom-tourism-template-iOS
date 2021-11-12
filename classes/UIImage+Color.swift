//
//  UIImage+Color.swift
//  tourismtemplate
//
//  Created by Thomas Krainz-Mischitz on 10.10.19.
//  Copyright © 2019 xamoom GmbH. All rights reserved.
//

import UIKit
import Foundation

extension UIImage {
  func imageWithColor(color: UIColor) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    color.setFill()
    
    let context = UIGraphicsGetCurrentContext()
    if let context = context {
      context.translateBy(x: 0, y: self.size.height)
      context.scaleBy(x: 1.0, y: -1.0);
      context.setBlendMode(CGBlendMode.normal)
      
      let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
      context.clip(to: rect, mask: self.cgImage!)
      context.fill(rect)
      
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      if let newImage = newImage {
        return newImage
      }
    }
    return self
  }
}
