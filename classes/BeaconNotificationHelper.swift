//
//  BeaconNotificationHelper.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 03/05/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import UserNotifications

class BeaconNotificationHelper {
  static let cooldownKey = "cooldownKey"
  static let backgroundLoadingTaskName = "backgroundLoadingTask"
  static var backgroundLoadingTask: UIBackgroundTaskIdentifier?
  static var isNotificationShown: [String: Bool] = [:]
  
  static func sendBeaconNotification(minor: NSNumber) {
    if shouldBeaconNotify(minor: minor) {
      loadContentWith(minor: minor)
    }
  }
    
    static func sendBeaconNotification(content: XMMContent) {
        if shouldBeaconNotify(contentId: content.id as! String) {
            showNotification(title: content.title, description: content.contentDescription, contentId: content.id as! String)
      }
    }
  
  static func removeAllNotifications() {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.removeAllPendingNotificationRequests()
      center.removeAllDeliveredNotifications()
    } else {
      UIApplication.shared.cancelAllLocalNotifications()
    }
    UIApplication.shared.applicationIconBadgeNumber = 0
    UIApplication.shared.cancelAllLocalNotifications()
  }
  
  static func showNotification(title:String, description: String, contentId: String) {
    
    let application = UIApplication.shared
    
    if let notifications = application.scheduledLocalNotifications {
      for not in notifications {
        if let userInfo = not.userInfo {
          if let cId = userInfo["contentId"] as? String {
            if cId == contentId {
              application.cancelLocalNotification(not)
            }
          }
        }
      }
    }
    
    let notification = UILocalNotification()
    notification.alertTitle = title
    notification.alertBody = description
    notification.fireDate = Date()
    notification.userInfo = ["contentId":contentId]
    
    AnalyticsHelper
      .reportCustomEvent(name: "Beacon Notification",
                         action: "Show beacon notification",
                         description: "For content: \(title)",
        code: nil)
    
    let isMuted = UserDefaults.standard.bool(forKey: Globals.Settings.notificationSoundMuted)
    if !isMuted {
      notification.soundName = UILocalNotificationDefaultSoundName
    }
    
    UIApplication.shared.scheduleLocalNotification(notification)
  }
  
  static func shouldBeaconNotify(minor: NSNumber) -> Bool {
    lastFetch(string: "shouldNotify")
    if(beaconMinorFileExists()){
      if let dic = NSDictionary(contentsOfFile: getDirectoryPath()) as? [String: Date] {
        lastFetch(string: "checkBeacons")
        if let lastDate = dic[minor.stringValue] {
          if lastDate.addingTimeInterval(TimeInterval(Globals.Beacon.cooldown)) >= Date() {
            coolDownFetch(string: "\(minor.stringValue)-cooldown", date: lastDate.addingTimeInterval(TimeInterval(Globals.Beacon.cooldown)))
            return false
          }
        }
      }
    }

    updateCooldown(minor: minor)
    return true
  }
    
    static func shouldBeaconNotify(contentId: String) -> Bool {
      
        if isNotificationShown.isEmpty || isNotificationShown[contentId] == nil {
          isNotificationShown[contentId] = false
          return true
      } else {
          return isNotificationShown[contentId] ?? true
      }
    }
  
  static func coolDownFetch(string: String, date: Date) {
    var dict: [String:Date] = [string : date]
    handleMinor(dict: dict)
  }
  
  static func lastFetch(string: String) {
    var dict: [String:Date] = [string : Date()]
    handleMinor(dict: dict)
  }
  
  
  static func updateCooldown(minor: NSNumber) {
    var dict: [String:Date] = [minor.stringValue : Date()]
    handleMinor(dict: dict)
  }
  
  static func handleMinor(dict: [String:Date]) {
    let path = getDirectoryPath()
    
    if(!beaconMinorFileExists()){
      
      saveBeaconMinorDictionary(dic: dict)
    } else {
      if let dic = NSDictionary(contentsOfFile: path) as? [String: Date] {
        var newDictionary = dic
        for (key, value) in dict {
          newDictionary.updateValue(value, forKey: key)
        }
        saveBeaconMinorDictionary(dic: newDictionary)
      }
    }
  }
  
  static func getDirectoryPath() -> String {
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    return documentDirectory.appending("/beaconminor.plist")
  }
  
  static func beaconMinorFileExists() -> Bool {
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: getDirectoryPath())
  }
  
  static func saveBeaconMinorDictionary(dic: [String:Date]) {
    let someData = NSDictionary(dictionary: dic)
    someData.write(toFile: getDirectoryPath(), atomically: true)
  }
  
  static func loadContentWith(minor: NSNumber) {
    backgroundLoadingTask = UIApplication.shared.beginBackgroundTask(withName: backgroundLoadingTaskName) {
      self.killBackgroundTask()
    }
    
    // stop here, if the user deactivated notifications.
    // So no loading is happening.
    if UserDefaults.standard.bool(forKey: Globals.Settings.notificationsOff) == true {
      self.killBackgroundTask()
      return
    }
    
    DispatchQueue.global().async() {
      ApiHelper.shared.downloadContent(withBeacon: minor,
                                       reason: .notificationContentRequest,
                                       completion: {
                                        (content) in
                                        if let content = content, let contentId = content.id as? String {
                                          showNotification(title: content.title, description: content.contentDescription, contentId: contentId)
                                        }
                                        
                                        self.killBackgroundTask()
      })
    }
  }
  
  static func killBackgroundTask() {
    DispatchQueue.main.async() {
      if let task = backgroundLoadingTask {
        UIApplication.shared.endBackgroundTask(task)
      }
      self.backgroundLoadingTask = UIBackgroundTaskInvalid
    }
  }
}
