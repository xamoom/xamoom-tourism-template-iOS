//
//  PushNotificationHelper.swift
//  tourismtemplate
//
//  Created by Petar Cekic on 05.02.20.
//  Copyright © 2020 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

class PushNotificationHelper {
  static func requestNotificationAuthorization(onGrantedCallback: @escaping () -> Void ) {
     if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          let center = UNUserNotificationCenter.current()
          center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            onGrantedCallback()
          }
      } else {
          let settings: UIUserNotificationSettings =
              UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          UIApplication.shared.registerUserNotificationSettings(settings)
      }
      UIApplication.shared.registerForRemoteNotifications()
    }
}
