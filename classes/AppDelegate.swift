//
//  AppDelegate.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 18/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import FirebaseCrashlytics
import CoreLocation
import UserNotifications
import XamoomSDK
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
  
  #if DEBUG
  let disableAnalytics = false
  #else
  let disableAnalytics = false
  #endif
  
  var errorHelper: ErrorHelper?
  var locationHelper: LocationHelper?
  let factory = ViewControllerFactory()


  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    Globals.apikey = AppGenHelper.sharedInstance.apiKey
    Globals.Beacon.major = NSNumber.init(value: AppGenHelper.sharedInstance.beaconMajor)
    Globals.trackingId = AppGenHelper.sharedInstance.trackingId
    Globals.Features.quiz = AppGenHelper.sharedInstance.isQuizFeatureShown

    var sound = !UserDefaults.standard.bool(forKey: Globals.Settings.notificationsOff)
    if sound {
      sound = !UserDefaults.standard.bool(forKey: Globals.Settings.notificationSoundMuted)
    }
    
    ApiHelper.shared.api.pushSound = sound
    
      if CLLocationManager.locationServicesEnabled() {
              switch CLLocationManager.authorizationStatus() {
                  case .notDetermined, .restricted, .denied:
                      break
                  case .authorizedAlways, .authorizedWhenInUse:
                      ApiHelper.shared.initLocationHelperWithBeacon()
                      locationHelper = ApiHelper.shared.locationHelper
                      locationHelper?.isDownloadBeaconContent = true
                  @unknown default:
                  break
              }
          }
    if let keys = launchOptions?.keys {
      if keys.contains(.location) {
        locationHelper?.stopLocationUpdating()
        locationHelper?.startLocationUpdateing()
      }
    }
    
    setupGoogleAnalytics()
    
    let firbaseOptions = FirebaseOptions(contentsOfFile: Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!)
    FirebaseApp.configure(options: firbaseOptions!)
    
    Globals.Color.primaryColor = AppGenHelper.sharedInstance.primaryColor
    Globals.Color.textColor = AppGenHelper.sharedInstance.textColor
    Globals.isBackgroundImage = AppGenHelper.sharedInstance.isBackgroundImage
    Globals.Color.barFontColor = AppGenHelper.sharedInstance.barTitleColor
    Globals.Color.tabbarSelected = Globals.Color.textColor
    Globals.Color.tabbarUnselected = Globals.Color.textColor
    
    XMMMapOverlayView.appearance().buttonBackgroundColor = Globals.Color.primaryColor
    XMMMapOverlayView.appearance().buttonTextColor = Globals.Color.tabbarSelected
    
    if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
      self.application(application, didReceiveRemoteNotification: notification)
    }
    
    application.registerForRemoteNotifications()

    setupPushNotification()
    changeAppearance()
        
    if disableAnalytics == false {
      Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
      AnalyticsHelper.registerSender(sender: FabricAnalyticsSender())
    } else {
      AnalyticsHelper.registerSender(sender: DebugAnalyticsSender())
    }
      
      if #available(iOS 15.0, *) {
          let appearanceStandart = UINavigationBarAppearance()
          appearanceStandart.configureWithOpaqueBackground()
          appearanceStandart.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
          appearanceStandart.shadowColor = .clear
          let appearanceScroll = UINavigationBarAppearance()
          appearanceScroll.configureWithOpaqueBackground()
          appearanceScroll.backgroundColor = nil
          appearanceScroll.shadowColor = .clear
          UINavigationBar.appearance().standardAppearance = appearanceStandart
          UINavigationBar.appearance().scrollEdgeAppearance = appearanceScroll
      } else {
          UINavigationBar.appearance().barTintColor = Globals.Color.primaryColor
          UINavigationBar.appearance().tintColor = Globals.Color.barFontColor
      }
    
    UITabBar.appearance().barTintColor = Globals.Color.primaryColor
    UITabBar.appearance().tintColor = Globals.Color.tabbarSelected
    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedStringKey.foregroundColor: Globals.Color.tabbarUnselected], for:.normal)
    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedStringKey.foregroundColor: Globals.Color.tabbarSelected], for:.selected)
    
    UISwitch.appearance().onTintColor = AppGenHelper.sharedInstance.primaryColor
    
    ApiHelper.shared.api.language = UserDefaults.standard.string(forKey: Globals.Settings.languageKey) ?? ApiHelper.shared.api.systemLanguage
    let userLanguage = UserDefaults.standard.string(forKey: Globals.Settings.languageKey) ?? ApiHelper.shared.api.language
    Bundle.setLanguage(userLanguage)
    UserDefaults.standard.set(userLanguage, forKey: Globals.Settings.languageKey)
    
    let tabbarController = setupNavigationStack()

    if UserDefaults.standard.bool(forKey: Globals.Settings.onboardingPassedKey) {
        window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = tabbarController
        self.window?.makeKeyAndVisible()
    }
    else {
        setupOnboarding(nextController: tabbarController)
    }
    
    locationHelper?.filterSameBeaconScans = true
    
    errorHelper = ErrorHelper.sharedInstance
    errorHelper?.startMonitoringForNetworkChange()
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didRangeBeacons(notification:)),
                                           name: NSNotification.Name(rawValue: BEACON_RANGE),
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didExitBeaconRegion(notification:)),
                                           name: NSNotification.Name(rawValue: BEACON_EXIT),
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(openContent(notification:)),
                                           name: NSNotification.Name.init(XAMOOM_NOTIFICATION_RECEIVE),
                                           object: nil)

    
//    startReceivingSignificantLocationChanges()
    
    ApiHelper.shared.pushDevice(instantPush: true)
    return true
  }
    
  private func hexFromColor(color: UIColor) -> String{
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
        
    }
    
  private func setupGoogleAnalytics() {
    guard let gai = GAI.sharedInstance() else {
        assert(false, "Google Analytics not configured correctly")
        return
    }
        
    gai.tracker(withTrackingId: Globals.trackingId)
        
    gai.trackUncaughtExceptions = true
  }
    
  func changeAppearance() {
      let backgroundColor = Globals.Color.primaryColor
      let tintColor = Globals.Color.textColor
    
      UserDefaults.standard.set(hexFromColor(color: backgroundColor), forKey: "template_primaryColor")
      let colorhex = hexFromColor(color: backgroundColor)

    
    
      if(Globals.isBackgroundImage.elementsEqual("true")) {
        XMMContentBlock1TableViewCell.appearance().audioPlayerBackgroundColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().facebookColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().fallbackColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().webColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().mailColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().wikipediaColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().itunesColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().appleColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().twitterColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().shopColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().linkedInColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().flickrColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().soundcloudColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().youtubeColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().googleColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().spotifyColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().androidColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().navigationColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().windowsColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().instagramColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().phoneColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().whatsAppColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock4TableViewCell.appearance().smsColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
        XMMContentBlock5TableViewCell.appearance().ebookColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
        XMMContentBlock8TableViewCell.appearance().calendarColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock8TableViewCell.appearance().contactColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlock8TableViewCell.appearance().gpxColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
        XMMMapOverlayView.appearance().buttonBackgroundColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
        XMMContentBlock11TableViewCell.appearance().loadMoreButtonTintColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
        XMMContentBlockEventTableViewCell.appearance().calendarColor = UIColor(patternImage: UIImage(named: "background_image")!)
        XMMContentBlockEventTableViewCell.appearance().navigationColor = UIColor(patternImage: UIImage(named: "background_image")!)
        
      } else {
        XMMContentBlock1TableViewCell.appearance().audioPlayerBackgroundColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().facebookColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().fallbackColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().webColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().mailColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().wikipediaColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().itunesColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().appleColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().twitterColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().shopColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().linkedInColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().flickrColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().soundcloudColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().youtubeColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().googleColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().spotifyColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().androidColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().navigationColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().windowsColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().instagramColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().phoneColor = backgroundColor
        XMMContentBlock4TableViewCell.appearance().whatsAppColor = backgroundColor;
        XMMContentBlock4TableViewCell.appearance().smsColor = backgroundColor;
        
        XMMContentBlock5TableViewCell.appearance().ebookColor = backgroundColor
        
        XMMContentBlock8TableViewCell.appearance().calendarColor = backgroundColor
        XMMContentBlock8TableViewCell.appearance().contactColor = backgroundColor
        XMMContentBlock8TableViewCell.appearance().gpxColor = backgroundColor
        
        XMMMapOverlayView.appearance().buttonBackgroundColor = backgroundColor
        
        XMMContentBlock11TableViewCell.appearance().loadMoreButtonTintColor = backgroundColor
        
        XMMContentBlockEventTableViewCell.appearance().calendarColor = backgroundColor
        XMMContentBlockEventTableViewCell.appearance().navigationColor = backgroundColor
      }
    
      
      XMMContentBlock1TableViewCell.appearance().audioPlayerTintColor = tintColor
      
    
      
      XMMContentBlock4TableViewCell.appearance().facebookTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().fallbackTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().webTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().mailTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().wikipediaTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().itunesTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().appleTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().twitterTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().shopTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().linkedInTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().flickrTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().soundcloudTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().youtubeTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().googleTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().spotifyTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().navigationTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().androidTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().windowsTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().instagramTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().phoneTintColor = tintColor
      XMMContentBlock4TableViewCell.appearance().whatsAppTintColor = tintColor;
      XMMContentBlock4TableViewCell.appearance().smsTintColor = tintColor;
      
      XMMContentBlock5TableViewCell.appearance().ebookTintColor = tintColor
      
      XMMContentBlock8TableViewCell.appearance().calendarTintColor = tintColor
      XMMContentBlock8TableViewCell.appearance().contactTintColor = tintColor
      XMMContentBlock8TableViewCell.appearance().gpxTintColor = tintColor
      
      
      XMMMapOverlayView.appearance().buttonTextColor = tintColor
      
      XMMContentBlockEventTableViewCell.appearance().calendarTintColor = tintColor
      XMMContentBlockEventTableViewCell.appearance().navigationTintColor = tintColor
  }
    
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    var sound: Bool = !UserDefaults.standard.bool(forKey: Globals.Settings.notificationsOff)
    if !sound {
      sound = !UserDefaults.standard.bool(forKey: Globals.Settings.notificationSoundMuted)
    }
    
    locationHelper?.pushSound = sound
    locationHelper?.stopLocationUpdating()
    locationHelper?.startLocationUpdateing()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    completionHandler(UIBackgroundFetchResult.newData)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Notification registration error: ", error.localizedDescription)
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { (result, error) in
      if let error = error {
        print("Error fetching remote instange ID: \(error)")
      } else if let result = result {
          XMMSimpleStorage().saveUserToken(result)
        ApiHelper.shared.pushDevice(instantPush: true)
      }
    }
  }
  
  func setupNavigationStack() -> UITabBarController {
    window = UIWindow(frame: UIScreen.main.bounds)
    
    let tabbarController = UITabBarController()
    
    let homeNavigationController: UINavigationController
    if (Globals.Features.quiz) {
        let homeViewController = factory.makeQuizHomeViewController()
        homeNavigationController = UINavigationController(rootViewController: homeViewController)
    } else {
        let homeViewController = factory.makeHomeViewController()
        homeNavigationController = UINavigationController(rootViewController: homeViewController)
    }
       
    let mapViewController = factory.makeMapViewController()
    let mapNavigationController = UINavigationController(rootViewController: mapViewController)
       
    let scanViewController = factory.makeScanViewController()
    let scanNavigationController = UINavigationController(rootViewController: scanViewController)
      
    let infoNavigationController: UINavigationController
    if (Globals.Features.quiz) {
        let infoViewController = factory.makeQuizContentViewController()
        infoNavigationController = UINavigationController(rootViewController: infoViewController)
    } else {
        let infoViewController = factory.makeContentViewController()
        infoNavigationController = UINavigationController(rootViewController: infoViewController)
    }
       
    let settingsViewController = factory.makeSettingsViewController()
    let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
    
    tabbarController.viewControllers = [homeNavigationController,
                                        mapNavigationController,
                                        scanNavigationController,
                                        infoNavigationController,
                                        settingsNavigationController]
    
      if #available(iOS 15.0, *) {
         let appearance = UITabBarAppearance()
         let tabBarItemAppearance = UITabBarItemAppearance()
         appearance.configureWithOpaqueBackground()
         appearance.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
         tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Globals.Color.tabbarUnselected]
         tabBarItemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Globals.Color.tabbarSelected]
         appearance.stackedLayoutAppearance = tabBarItemAppearance
         tabbarController.tabBar.standardAppearance = appearance
         tabbarController.tabBar.scrollEdgeAppearance = appearance
      } else {
          if Globals.isBackgroundImage.elementsEqual("true") {
              tabbarController.tabBar.barTintColor = UIColor(patternImage: UIImage(named: "background_image")!)
              tabbarController.tabBar.clipsToBounds = true
          }
      }
    
    return tabbarController
  }
  
    func setupOnboarding(nextController: UIViewController) {
        let onboardController = OnboardViewController()
        onboardController.nextControllerToLoad = nextController
        self.window?.rootViewController = onboardController
        self.window?.makeKeyAndVisible()
    }
    
    func setupPushNotification() {
        let helper = PushHelper.init(api: ApiHelper.shared.api)
        Messaging.messaging().delegate = helper?.messagingDelegate
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = helper?.notificationDelegate
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
  @objc func didRangeBeacons(notification: Notification) {
    var beacons: [XMMContent] = []
    
    if let items = notification.userInfo?[XAMOOM_BEACONS_KEY] {
      beacons = items as! [XMMContent]
    }
    
    if beacons.count > 0 {
      if let content = beacons.first {
        BeaconNotificationHelper.sendBeaconNotification(content: content)
      }
    }
  }
  
  @objc func didExitBeaconRegion(notification: Notification) {
    BeaconNotificationHelper.removeAllNotifications()
  }
  
  func startReceivingSignificantLocationChanges() {
    let authorizationStatus = CLLocationManager.authorizationStatus()
    if authorizationStatus != .authorizedAlways {
      // User has not authorized access to location information.
      return
    }
    
    if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
      // The service is not available.
      return
    }
    
    let locationManager = CLLocationManager()
    locationManager.delegate = self
    //locationManager.distanceFilter = kCLDistanceFilterNone
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.allowsBackgroundLocationUpdates = true
    //locationManager.requestAlwaysAuthorization()
    //locationManager.startMonitoringSignificantLocationChanges()
    locationManager.startUpdatingLocation()
  }
  
  @objc func openContent(notification: NSNotification) {
    if let contentId = notification.userInfo?["contentId"] as? String {
      let controller = ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
      controller.contentId = contentId
      controller.isBeacon = true
      controller.hidesBottomBarWhenPushed = true
      let tabCon = self.window?.rootViewController as! UITabBarController
      tabCon.selectedIndex = 0
      let navcon = tabCon.selectedViewController as! UINavigationController
      navcon.pushViewController(controller, animated: true)
    } else if let cId = notification.userInfo?["content-id"] as? String {
      let controller = ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
      controller.contentId = cId
      controller.isBeacon = true
      controller.hidesBottomBarWhenPushed = true
      let tabCon = self.window?.rootViewController as! UITabBarController
      tabCon.selectedIndex = 0
      let navcon = tabCon.selectedViewController as! UINavigationController
      navcon.pushViewController(controller, animated: true)
    } else {
      let controller = HomeViewController(nibName: "HomeViewController", bundle: Bundle.main)
      let tabCon = self.window?.rootViewController as! UITabBarController
      tabCon.selectedIndex = 0
      let navcon = tabCon.selectedViewController as! UINavigationController
      navcon.pushViewController(controller, animated: true)
    }
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    return true
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
      let path = url.path
      if path != "" && path != "/" {
        let controller = ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
        
        if path.contains("content/") {
          let contentId = self.locationIdFrom(urlString: url.absoluteString)
          controller.contentId = contentId
          
        } else {
          let locId = self.locationIdFrom(urlString: url.absoluteString)
          controller.locId = locId
        }
        
        controller.isBeacon = false
        controller.hidesBottomBarWhenPushed = true
        let tabCon = self.window?.rootViewController as! UITabBarController
        tabCon.selectedIndex = 0
        let navcon = tabCon.selectedViewController as! UINavigationController
        navcon.popToRootViewController(animated: true)
        navcon.pushViewController(controller, animated: true)
      } else {
        let tabCon = self.window?.rootViewController as! UITabBarController
        tabCon.selectedIndex = 0
        let navcon = tabCon.selectedViewController as! UINavigationController
        navcon.popToRootViewController(animated: true)
      }
    }
    return true
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
      let path = url.path
      if path != "" && path != "/" {
        let controller = ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
        
        if path.contains("content/") {
          let contentId = self.locationIdFrom(urlString: url.absoluteString)
          controller.contentId = contentId
          
        } else {
          let locId = self.locationIdFrom(urlString: url.absoluteString)
          controller.locId = locId
        }
        
        controller.isBeacon = false
        controller.hidesBottomBarWhenPushed = true
        let tabCon = self.window?.rootViewController as! UITabBarController
        tabCon.selectedIndex = 0
        let navcon = tabCon.selectedViewController as! UINavigationController
        navcon.popToRootViewController(animated: true)
        navcon.pushViewController(controller, animated: true)
      } else {
        let tabCon = self.window?.rootViewController as! UITabBarController
        tabCon.selectedIndex = 0
        let navcon = tabCon.selectedViewController as! UINavigationController
        navcon.popToRootViewController(animated: true)
      }
    }
    return true
  }
  
  private func locationIdFrom(urlString: String) -> String? {
    let url = URL(string: urlString)
    if let url = url {
      return url.lastPathComponent
    }
    
    return nil
  }
}

