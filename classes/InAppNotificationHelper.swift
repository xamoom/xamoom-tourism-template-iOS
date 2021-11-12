//
//  InAppNotificationHelper.swift
//  kollitsch-art
//
//  Created by Raphael Seher on 06/03/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

class InAppNotificationHelper: NSObject {
  var view : UIView?
  
  func showNotification(message: String) {
    let notificationView = Bundle.main.loadNibNamed("NotificationView",
                                                    owner: self,
                                                    options: nil)?[0] as? NotificationView
    if let notificationView = notificationView {
      notificationView.message = message
      view?.addSubview(notificationView)
    }
  }
}
