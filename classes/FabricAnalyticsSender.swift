//
//  FabricAnalyticsSender.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 12/07/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import Firebase

class FabricAnalyticsSender: NSObject, AnalyticsSender {
  func reportError(name: String, domain: String, description: String, code: Int) {
    
    Analytics.logEvent(name, parameters: [
        "Error_Domain": domain,
        "Error_Description": description,
        "Error_Code": code
    ])
  }
  
  func reportContentView(name: String, contentTyp: String, id: String, customAttributes: Dictionary<String, String>?) {
    
    var parameters = [
      AnalyticsParameterItemName: name,
      AnalyticsParameterContentType: contentTyp,
      AnalyticsParameterItemID: id
    ]
    
    if (customAttributes != nil) {
      parameters.merge(customAttributes!, uniquingKeysWith: { (_, new) in new })
    }
    
    Analytics.logEvent("AnalyticsEventViewItem", parameters: parameters)
    
  }
  
  func reportCustomEvent(name: String, action: String?, description: String?, code: Int?) {
    
    Analytics.logEvent(name, parameters: [
        "Action": action ?? "",
        "Description": description ?? "",
        "Code": code ?? ""
    ])
  }
}
