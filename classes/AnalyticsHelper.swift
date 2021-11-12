//
//  AnalyticsHelper.swift
//  kollitsch-art
//
//  Created by Raphael Seher on 06/03/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

protocol AnalyticsSender {
  func reportError(name: String, domain: String, description: String, code: Int)
  func reportContentView(name: String, contentTyp: String, id: String, customAttributes: Dictionary<String, String>?)
  func reportCustomEvent(name: String, action: String?, description: String?, code: Int?)
}

class AnalyticsHelper: NSObject {
  static let errorName = "Error";
  
  static var analyticsSender: [AnalyticsSender] = []
  
  static func reportError(type: String, error: NSError) {
    for sender in analyticsSender {
      sender.reportError(name: errorName,
                         domain: type,
                         description: error.localizedDescription,
                         code: error.code)
    }
  }
    
  static func reportGoogleAnalyticsScreen(screenName: String) {
      guard let tracker = GAI.sharedInstance().defaultTracker else { return }
      tracker.set(kGAIScreenName, value: screenName)

      guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
      tracker.send(builder.build() as [NSObject : AnyObject])
  }
  
  static func reportContentView(contentName: String, contentType: String, contentId: String, customAttributes: Dictionary<String, String>?) {
    for sender in analyticsSender {
      sender.reportContentView(name: contentName,
                               contentTyp: contentType,
                               id: contentId,
                               customAttributes: customAttributes)
    }
  }
  
  static func reportCustomEvent(name: String, action: String?, description: String?, code: Int?) {
    for sender in analyticsSender {
      sender.reportCustomEvent(name: name, action: action, description: description, code: code)
    }
  }
  
  static func registerSender(sender: AnalyticsSender) {
    analyticsSender.append(sender)
  }
}
