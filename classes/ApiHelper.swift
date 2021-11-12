//
//  ApiHelper.swift
//  Kollitsch Art
//
//  Created by Raphael Seher on 22/02/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

class ApiHelper: NSObject {
  static let shared = ApiHelper()
  
  let api: XMMEnduserApi = XMMEnduserApi(apiKey: Globals.apikey, isProduction: true)
  var locationHelper : LocationHelper = LocationHelper()

  let notificationHelper = InAppNotificationHelper()
  
  var system: XMMSystem?
  var settings: XMMSystemSettings?
  var style: XMMStyle?
  var isLoading = false  

    func initLocationHelperWithBeacon() {
        locationHelper = LocationHelper(beaconRegion: Globals.Beacon.uuid, beaconMajor: Globals.Beacon.major, beaconIdentifier: Globals.Beacon.klagenfurtBeaconIdentifier, api: XMMEnduserApi(apiKey: Globals.apikey, isProduction: true))
    }

  override init() {
    super.init()
    downloadSystem(completion: {system in
      if let system = system {
        self.downloadSettings(withID: system.id as! String, completion: nil)
      }
    })
  }
  
  func cancelTasks() {
    api.restClient.session.getTasksWithCompletionHandler(
      {(dataTasks, uploadTasks, downloadTasks) in
        print("Running tasks to cancel: \(dataTasks.count)")
        for task in dataTasks {
          task.suspend()
        }
    })
  }
  
  func deviceLanguage() -> String {
    return api.language
  }
  
  func downloadSystem(completion: ((XMMSystem?) -> (Void))?) {
    if (system != nil) {
      if (style == nil) {
        self.downloadStyle(system: system!, completion: nil)
      }
      return
    }
    
    api.system { (system, error) in
      if (error != nil) {
        return
      }
      
      if let system = system {
        self.system = system
        self.downloadStyle(system: system, completion: nil)
        completion?(system)
      }
    }
  }
  
  func downloadStyle(system: XMMSystem, completion: ((XMMStyle?) -> (Void))?) {
    if (self.style != nil) {
      completion?(self.style)
    }
    
    let systemId: String = system.id as! String
    api.style(withID: systemId) { (style, error) in
      if (error != nil) {
        return
      }
      
      if let style = style {
        self.style = style
        
        completion?(style)
      }
    }
  }
  
  func downloadSettings(withID id: String, completion: ((XMMSystemSettings) -> (Void))?) {
    self.api.systemSettings(withID: id) { (settings, error) in
      if (error != nil) {
        return
      }
        
      if let settings = settings {
        self.settings = settings
        UserDefaults.standard.set(settings.isFormActive, forKey: Globals.Settings.isFormsActive)
        UserDefaults.standard.set(settings.formsBaseUrl, forKey: Globals.Settings.formsBaseUrl)
        UserDefaults.standard.set(settings.isSocialSharingEnabled, forKey: Globals.Settings.isSocialSharingEnabled)
        if (settings.isLanguagePickerEnabled) {
          self.api.language = UserDefaults.standard.string(forKey: Globals.Settings.languageKey) ?? self.api.systemLanguage
          Bundle.setLanguage(self.api.language)
        } else {
          UserDefaults.standard.set(nil, forKey: Globals.Settings.languageKey)
        }
        completion?(settings)
      }
    }
  }
  
  func downloadContents(withTag tag: String,
                        cursor: String?,
                        desc: Bool = false,
                        completion: @escaping (Array<XMMContent>, String, Bool) -> Void) {
    let pageSize = 10 as Int32
    
    var sort = XMMContentSortOptions.title
    if (desc) {
      sort = XMMContentSortOptions.titleDesc
    }
    
    isLoading = true
    api.contents(withTags: [tag], pageSize: pageSize, cursor: cursor,
                 sort: sort,
                 completion: { (contents, hasMore, cursor, error) in
                  self.isLoading = false
                  if let error = error {
                    self.handleError(error: error, recoverCallback: {
                      self.downloadContents(withTag: tag, cursor: cursor, desc: desc, completion: completion)
                    })
                    completion([], "", false)
                    return
                  }
                  
                  if (contents != nil) {
                    completion(contents as! Array<XMMContent>, cursor!, hasMore)
                  }
    });
  }
  
  func downloadContent(withId contentId: String,
                       controller: UIViewController,
                       completion: @escaping (XMMContent?) -> Void) {
    downloadContent(withId: contentId, reason: .unknown, controller: controller, completion: completion)
  }
  
  func downloadContent(withId contentId: String,
                       reason: XMMContentReason,
                       controller: UIViewController,
                       completion: @escaping (XMMContent?) -> Void) {
    isLoading = true
    api.content(withID: contentId,
                options: XMMContentOptions(rawValue: 0), reason: reason, password: nil) {
                  (content, error, passwordReuired) in
                  self.isLoading = false
                  
                  if passwordReuired {
                    self.showPasswordAlert(contentId: contentId, vc: controller, reason: reason, completion: completion)
                  } else if let error = error {
                    self.handleError(error: error, recoverCallback: {
                      self.downloadContent(withId: contentId, controller: controller, completion: completion)
                    })
                    completion(nil)
                    return
                  } else {
                    completion(content)
                  }
    }
  }
  
  func downloadContent(withLocationIdentifier locId: String!,
                       controller: UIViewController,
                       completion: @escaping (XMMContent?) -> Void) {
    downloadContent(withLocationIdentifier: locId, reason: .unknown, controller: controller,
                    completion: completion);
  }
  
  func downloadContent(withLocationIdentifier locId: String!,
                       reason: XMMContentReason,
                       controller: UIViewController,
                       completion: @escaping (XMMContent?) -> Void) {
    isLoading = true
    
    api.content(withLocationIdentifier: locId,
                options: XMMContentOptions.init(rawValue: 0),
                password: nil) {
                  (content, error, passwordRequired) in
                  self.isLoading = false
                  if passwordRequired {
                    self.showPasswordAlert(locationIdentifier: locId, vc: controller, reason: reason, completion: completion)
                  } else if let error = error {
                    self.handleError(error: error, recoverCallback: {
                      self.downloadContent(withLocationIdentifier: locId, controller: controller, completion: completion)
                    })
                    completion(nil)
                    return
                  } else {
                    completion(content)
                  }
    }
  }
  
  func downloadContent(withBeacon minor: NSNumber,
                       completion: @escaping (XMMContent?) -> Void) {
    downloadContent(withBeacon: minor, reason: .unknown, completion: completion);
  }
  
  func downloadContent(withBeacon minor: NSNumber,
                       reason: XMMContentReason,
                       completion: @escaping (XMMContent?) -> Void) {
    isLoading = true
    
    api.content(withBeaconMajor: Globals.Beacon.major, minor: minor,
                options: XMMContentOptions(rawValue: 0),
                conditions: nil, reason: reason) { (content, error, passwordRequired) in
      self.isLoading = false
      if let error = error {
        self.handleError(error: error, recoverCallback: {
          self.downloadContent(withBeacon: minor, completion: completion)
        })
        completion(nil)
        return
      }
      
      completion(content)
    }
  }
  
  func getVoucherStatus(withId contentId: String,
                        completion: @escaping (Bool) -> Void) {
    api.voucherStatus(withContendID: contentId, clientID: nil, completion: {(status, error) in
      if error != nil {
        completion(true)
        return
      }
      completion(status)
    })
  }
  
  func redeemVoucher(withId contentId: String,
                     redeemCode: String,
                     completion: @escaping (Bool?, Error?) -> Void) {
    api.redeemVoucher(withContendID: contentId, clientID: nil, redeemCode: redeemCode, completion: {(status, error) in
      if let error = error {
        completion(nil, error)
        return
      }
      completion(status, nil)
    })
  }
  
  func downloadSpot(id: String!, completion: @escaping (XMMSpot?) -> Void) {
    isLoading = true
    
    api.spot(withID: id, options: XMMSpotOptions.includeContent) {
      (spot, error) in
      self.isLoading = false
      if let error = error {
        self.handleError(error: error, recoverCallback: {
          self.downloadSpot(id: id, completion: completion)
        })
        completion(nil)
        return
      }
      
      completion(spot)
    }
  }
  
  func downloadSpots(tags: [String], cursor: String?, completion: @escaping (Array<XMMSpot>, String, Bool) -> Void) {
    isLoading = true
    
    api.spots(withTags: tags, pageSize: 100, cursor: cursor, options: [.withLocation, .includeContent, .includeMarker], sort: .init(rawValue: 0)) { (spots, hasMore, cursor, error) in
      self.isLoading = false
      
      if let error = error {
        self.handleError(error: error, recoverCallback: {
          self.downloadSpots(tags: tags, cursor: cursor, completion: completion)
        })
        completion([], "", false)
        
        return
      }
      
      if let spots = spots {
        completion(spots as! Array<XMMSpot>, cursor!, hasMore)
      }
    }
  }
  
  func handleError(error: Error, recoverCallback: (() -> Void)?) {
    AnalyticsHelper.reportError(type: "Network", error: error as NSError)
    ErrorHelper.sharedInstance.handleError(error: error as NSError, recoverCallback: recoverCallback)
  }
  
  func pushDevice(instantPush: Bool) {
    api.pushDevice(instantPush)
  }
  
  func showPasswordAlert(contentId: String, vc: UIViewController, reason: XMMContentReason, completion: @escaping (XMMContent?) -> Void) {
    let alertController = UIAlertController(title: NSLocalizedString("password.dialog.title", comment: ""), message: nil, preferredStyle: .alert)
    
    //the confirm action taking the inputs
    let confirmAction = UIAlertAction(title: NSLocalizedString("password.dialog.continue", comment: ""), style: .default) { (_) in
      
      //getting the input values from user
      let name = alertController.textFields?[0].text
      
      self.api.content(withID: contentId,
                       options: XMMContentOptions(rawValue: 0), reason: reason, password: name) { (c, e, p) in
                        
                        if p {
                          self.showPasswordAlert(contentId: contentId, vc: vc, reason: reason, completion: completion)
                          return
                        }else if let e = e {
                          self.handleError(error: e, recoverCallback: {
                            self.downloadContent(withId: contentId, controller: vc, completion: completion)
                          })
                          completion(nil)
                          return
                        } else {
                          completion(c)
                        }
      }
    }
    
    //the cancel action doing nothing
    let cancelAction = UIAlertAction(title: NSLocalizedString("password.dialog.cancel", comment: ""), style: .cancel) { (_) in
      completion(nil)
      return
    }
    
    //adding textfields to our dialog box
    alertController.addTextField { (textField) in
      textField.placeholder = NSLocalizedString("password.dialog.hint", comment: "")
      textField.isSecureTextEntry = true
    }
    
    //adding the action to dialogbox
    alertController.addAction(confirmAction)
    alertController.addAction(cancelAction)
    
    //finally presenting the dialog box
    vc.present(alertController, animated: true, completion: nil)
  }
  
  func showPasswordAlert(locationIdentifier: String, vc: UIViewController, reason: XMMContentReason, completion: @escaping (XMMContent?) -> Void) {
    let alertController = UIAlertController(title: NSLocalizedString("password.dialog.title", comment: ""), message: nil, preferredStyle: .alert)
    
    //the confirm action taking the inputs
    let confirmAction = UIAlertAction(title: NSLocalizedString("password.dialog.continue", comment: ""), style: .default) { (_) in
      
      //getting the input values from user
      let name = alertController.textFields?[0].text
      
      self.api.content(withLocationIdentifier: locationIdentifier,
                       options: XMMContentOptions.init(rawValue: 0),
                       password: name) { (c, e, p) in
                        
                        if p {
                          self.showPasswordAlert(locationIdentifier: locationIdentifier, vc: vc, reason: reason, completion: completion)
                          return
                        }else if let e = e {
                          self.handleError(error: e, recoverCallback: {
                            self.downloadContent(withLocationIdentifier: locationIdentifier, controller: vc, completion: completion)
                          })
                          completion(nil)
                          return
                        } else {
                          completion(c)
                        }
      }
    }
    
    //the cancel action doing nothing
    let cancelAction = UIAlertAction(title: NSLocalizedString("password.dialog.cancel", comment: ""), style: .cancel) { (_) in
      completion(nil)
      return
    }
    
    //adding textfields to our dialog box
    alertController.addTextField { (textField) in
      textField.placeholder = NSLocalizedString("password.dialog.hint", comment: "")
      textField.isSecureTextEntry = true
    }
    
    //adding the action to dialogbox
    alertController.addAction(confirmAction)
    alertController.addAction(cancelAction)
    
    //finally presenting the dialog box
    vc.present(alertController, animated: true, completion: nil)
  }
}
