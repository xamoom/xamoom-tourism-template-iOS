//
//  GenHelper.swift
//  tourismtemplate
//
//  Created by Raphael Seher on 31/08/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import Foundation
import UIKit

class AppGenHelper {
  let genPlistFileName = "gen"
  let appNameKey = "app-name"
  let apiKeyKey = "api-key"
  let apiTrackingIdKey = "tracking_id"
  let mapsKeyKey = "maps-api-key"
  let primaryColorKey = "primary-color"
  let textColorKey = "text_color"
  let isBackgroundImageKey = "is_background_image"
  let primaryDarkColorKey = "primary-color-dark"
  let accentColorKey = "accent-color"
  let beaconMajorKey = "beacon-major"
  let isQuizFeatureShownKey = "enable_quiz_feature"
  let unselectedTabbarColorBright = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
  let unselectedTabbarColorDark = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
  
  static let sharedInstance = AppGenHelper()
  
  var appName = "AppGenTemplate"
  var apiKey = "no api key found"
  var trackingId = "no tracking id found"
  var mapsKey = "no maps key found"
  var primaryColor = UIColor.white
  var primaryDarkColor = UIColor.lightGray
  var accentColor = UIColor.blue
  var textColor = UIColor.white
  var isBackgroundImage = "false"
  var barTitleColor = UIColor.black
  var tabbarItemColorSelected = UIColor.black
  var tabbarItemColorUnselected = UIColor.black
  var beaconMajor = 0
  var isQuizFeatureShown = false
  
  init() {
    initProperties()
    generateForegroundColors()
  }
  
  func initProperties() {
    var genPlist: NSDictionary?
    
    if let path =  Bundle.main.path(forResource: genPlistFileName,
                                    ofType: "plist") {
      genPlist = NSDictionary(contentsOfFile: path)
    }
    
    guard genPlist != nil else {
      return
    }
    
    if let appNameString =  genPlist?.object(forKey: appNameKey) as? String {
      appName = appNameString
    }
    if let apiKeyString = genPlist?.object(forKey: apiKeyKey) as? String {
      apiKey = apiKeyString
    }
    if let mapsKeyString = genPlist?.object(forKey: mapsKeyKey) as? String {
      mapsKey = mapsKeyString
    }
    
    if let trackerIdString = genPlist?.object(forKey: apiTrackingIdKey) as? String {
            trackingId = trackerIdString
    }

  
    if let primaryString = genPlist?.object(forKey: primaryColorKey) as? String {
      primaryColor = UIColor.init(hexString: primaryString)
    }
    
    if let textColorString = genPlist?.object(forKey: textColorKey) as? String {
      textColor = UIColor.init(hexString: textColorString)
    }
    
    if let isBackgroundImageString = genPlist?.object(forKey: isBackgroundImageKey) as? String {
      isBackgroundImage = isBackgroundImageString
    }
  
    if let primaryDarkString = genPlist?.object(forKey: primaryDarkColorKey) as? String {
      primaryDarkColor = UIColor.init(hexString: primaryDarkString)
    }
  
    if let accentString = genPlist?.object(forKey: accentColor) as? String {
      accentColor = UIColor.init(hexString: accentString)
    }
    
    if let isQuizFeatureShownBool = genPlist?.object(forKey: isQuizFeatureShownKey) as? String {
        isQuizFeatureShown = (isQuizFeatureShownBool as NSString).boolValue
    }
    
    if let majorString = genPlist?.object(forKey: beaconMajorKey) as? String {
      if let majorNumber = Int(majorString) {
        beaconMajor = majorNumber
      }
    }
  }
  
  func generateForegroundColors() {
    barTitleColor = primaryColor.isDark ? UIColor.white : UIColor.black
    tabbarItemColorSelected = barTitleColor
    tabbarItemColorUnselected = primaryColor.isDark ? unselectedTabbarColorBright : unselectedTabbarColorDark
  }
}

extension UIColor {
  convenience init(hexString: String) {
    let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt32()
    Scanner(string: hex).scanHexInt32(&int)
    let a, r, g, b: UInt32
    switch hex.characters.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
  }
  
  convenience init(hex: String, alpha: CGFloat = 1) {
    var hex = hex.replacingOccurrences(of: "#", with: "")
    
    guard hex.characters.count == 3 || hex.characters.count == 6 else {
      fatalError("Hex characters must be either 3 or 6 characters")
    }
    
    if hex.characters.count == 3 {
      var tmp = hex
      hex = ""
      for c in tmp.characters {
        hex += String([c,c])
      }
    }
    
    let scanner = Scanner(string: hex)
    var rgb: UInt32 = 0
    scanner.scanHexInt32(&rgb)
    
    let R = CGFloat((rgb >> 16) & 0xFF)/255
    let G = CGFloat((rgb >> 8) & 0xFF)/255
    let B = CGFloat(rgb & 0xFF)/255
    self.init(red: R, green: G, blue: B, alpha: alpha)
  }
  
  var RGBA: [CGFloat] {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue, alpha]
  }
  
  /**
   Get the relative luminosity value of the color. This follows the W3 specs of luminosity
   to give weight to colors which humans perceive more of.
   
   - returns: A CGFloat representing the relative luminosity.
   */
  var luminance: CGFloat {
    // http://www.w3.org/WAI/GL/WCAG20-TECHS/G18.html
    
    let RGBA = self.RGBA
    
    func lumHelper(c: CGFloat) -> CGFloat {
      return (c < 0.03928) ? (c/12.92): pow((c+0.055)/1.055, 2.4)
    }
    
    return 0.2126 * lumHelper(c: RGBA[0]) + 0.7152 * lumHelper(c: RGBA[1]) + 0.0722 * lumHelper(c: RGBA[2])
  }
  
  /**
   Determine if the color is dark based on the relative luminosity of the color.
   
   - returns: A boolean: true if it is dark and false if it is not dark.
   */
  var isDark: Bool {
    return self.luminance < 0.5
  }
  
  /**
   Determine if the color is light based on the relative luminosity of the color.
   
   - returns: A boolean: true if it is light and false if it is not light.
   */
  var isLight: Bool {
    return !self.isDark
  }
}

extension UIImage {
  func resizeImage(newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  func imageWithColor(color1: UIColor) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    color1.setFill()
    
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
