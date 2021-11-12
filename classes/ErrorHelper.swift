//
//  ErroHelper.swift
//  Programmpresentation-ORF
//
//  Created by Raphael Seher on 31/08/16.
//  Copyright © 2016 xamoom GmbH. All rights reserved.
//

import Foundation
import Reachability

class ErrorHelper : NSObject {
  static let sharedInstance : ErrorHelper! = ErrorHelper()
  
  var window : UIWindow?
  var reach: Reachability?
  var isOffline = false
  var lastCallback : (() -> Void)?
  var inAppNotificationHelper = InAppNotificationHelper()
  
  override init() {
    self.reach = Reachability.forInternetConnection()
    let window = UIApplication.shared.windows.first
    inAppNotificationHelper.view = window
    super.init()
  }
  
  func startMonitoringForNetworkChange() {
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(reachabilityChanged),
                   name: NSNotification.Name.reachabilityChanged,
                   object: nil)
    
    self.reach!.startNotifier()
  }
  
  @objc func reachabilityChanged(notification: NSNotification) {
    if self.reach!.isReachableViaWiFi() || self.reach!.isReachableViaWWAN() {
      if isOffline {
        isOffline = false
        if let callback = lastCallback {
          callback()
        }
      }
    } else {
      isOffline = true
    }
  }
  
  func handleError(error: NSError!, recoverCallback: (() -> Void)?) {
    lastCallback = recoverCallback

    var message = NSLocalizedString("error.default", comment: "")
    
    if error.code == -1009 {
      message = NSLocalizedString("error.no_internet", comment: "")
      isOffline = true
    }
    
    inAppNotificationHelper.showNotification(message: message)
  }
}
