//
//  DebugAnalyticsSender.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 12/07/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

class DebugAnalyticsSender: NSObject, AnalyticsSender {

  func reportError(name: String, domain: String, description: String, code: Int) {
    print("⭕️ [Error] \n name: \(name) \n domain: \(domain)" +
      "\n description: \(description) \n code: \(code)")
  }
  
  func reportContentView(name: String, contentTyp: String, id: String, customAttributes: Dictionary<String, String>?) {
    print("⭕️ [Content View] \n name: \(name) \n contentTyp: \(contentTyp)" +
      "\n id: \(id) \n customAttributes: \(String(describing: customAttributes))")
  }
  
  func reportCustomEvent(name: String, action: String?, description: String?, code: Int?) {
    print("⭕️ [Custom Event] \n name: \(name) \n action: \(String(describing: action))" +
      "\n description: \(String(describing: description)) \n code: \(String(describing: code))")
  }
  
}
