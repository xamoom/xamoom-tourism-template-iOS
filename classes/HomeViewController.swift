//
//  ViewController.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 18/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import ImageSlideshow
import XamoomSDK
import MBProgressHUD

enum DisplayType {
  case Slider
  case Nearby
  case Horizontal
  case Guide
}

class HomeViewController: UIViewController, ContentInteractionProtocol {
  @IBOutlet weak var statusBarOverlayView: UIVisualEffectView!
  @IBOutlet weak var tableView: UITableView!
  
  
  var orientations: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
  var beaconAvailable = true
  var elementTypes: [DisplayType] = [DisplayType.Slider]
  var elementTags: [String?] = [nil]
  var config: [AnyHashable : Any] = [:]
  var geofenceSpots: [XMMSpot] = []
  var geofenceSpotsSaved: [XMMSpot] = []
  var userActiveRegionContent: [XMMContent] = []
  var savedRegionContent: [XMMContent] = []
  lazy var locationManager = CLLocationManager()
  lazy var currentLocation = CLLocation()
  var monitoringRegions: [CLRegion] = []
  var timerGeofenceRegionUpdate: Timer = Timer()
  var isNeedToSendGeaogenseRequest: Bool = true
  var locationHelper: LocationHelper?
  var isGeofenceContentLoaded = false
  var isTimerEnabled = true
  
  var nearbyContentsTemp: [XMMContent] = []
  var nearbyContents: [XMMContent] = [] {
    didSet {
      nearbyContentSizeChanged = false
      if oldValue.count != nearbyContents.count {
        nearbyContentSizeChanged = true
      }
      
        if nearbyContents.count == 0 {
          removeNearby()
        } else {
          addNearby()
      }
    }
  }
  // If beaconContents parameter changes, the setter will be called.
  var beaconContents: [XMMContent] = [] {
    didSet {
        if oldValue.count != beaconContents.count {
            if beaconContents.count == 0 && nearbyContents != userActiveRegionContent {
                nearbyContents = userActiveRegionContent
            } else {
                var content: [XMMContent] = []
                content.append(contentsOf: beaconContents)
                content.append(contentsOf: userActiveRegionContent)
                nearbyContents = content
            }
        }
    }
  }
  
  var nearbyContentSizeChanged = false
  var nothingFoundView: NothingFoundView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let insets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height * -1,
                              left: self.tableView.contentInset.left,
                              bottom: self.tableView.contentInset.bottom,
                              right: self.tableView.contentInset.right)
    self.tableView.contentInset = insets
    
    locationManager.delegate = self
//    timerGeofenceRegionUpdate = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
//        print("TIMERRR \(self.isTimerEnabled)")
//        if (self.isTimerEnabled) {
//            self.downloadGeofenceRegions()
//
//        }
//    }
    ApiHelper.shared.initLocationHelperWithBeacon()
    locationHelper = ApiHelper.shared.locationHelper
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Home screen")
    AnalyticsHelper.reportContentView(contentName: "Home",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: "",
                                      customAttributes: nil)
    initTableView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    isTimerEnabled = true
    locationHelper?.isDownloadBeaconContent = true
    self.navigationController?.isNavigationBarHidden = true
    locationManager.startUpdatingLocation()
    isNeedToSendGeaogenseRequest = true
//    geofenceSpotsSaved = []
    initizializeStartGrid()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didRangeBeaconContents(notification:)),
                                           name: NSNotification.Name(rawValue: BEACON_CONTENTS),
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didExitBeaconRegion(notification:)),
                                           name: NSNotification.Name(rawValue: BEACON_EXIT),
                                           object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillTerminate, object: nil)
      timerGeofenceRegionUpdate.invalidate()
      timerGeofenceRegionUpdate = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
          self.downloadGeofenceRegions()
      }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    isTimerEnabled = false
    timerGeofenceRegionUpdate.invalidate()
    NotificationCenter.default.removeObserver(self,
                                              name: NSNotification.Name(rawValue: BEACON_CONTENTS),
                                              object: nil)
    NotificationCenter.default.removeObserver(self,
                                              name: NSNotification.Name(rawValue: BEACON_EXIT),
                                              object: nil)
    stopMonitoringRegions()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    
  @objc func appMovedToForeground(_ notification: Notification) {
      isTimerEnabled = true
      startUpdatingLocation()
      timerGeofenceRegionUpdate.invalidate()
      timerGeofenceRegionUpdate = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
          self.downloadGeofenceRegions()
      }
  }
  
  @objc func appMovedToBackground(_ notification: Notification) {
      isTimerEnabled = false
      timerGeofenceRegionUpdate.invalidate()
      stopUpdatingLocation()
  }
    
  deinit {
      timerGeofenceRegionUpdate.invalidate()
  }
  
  func initTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.separatorStyle = .none
    tableView.estimatedRowHeight = 200
    tableView.rowHeight = UITableViewAutomaticDimension
    
    tableView.register(UINib(nibName: "HorizontalContentTableViewCell", bundle: Bundle.main),
                       forCellReuseIdentifier: HorizontalContentTableViewCell.identifier)
    tableView.register(UINib(nibName: "ImageSliderTableViewCell", bundle: Bundle.main),
                       forCellReuseIdentifier: ImageSliderTableViewCell.identifier)
  }
  
  @objc func didExitBeaconRegion(notification: Notification) {
    beaconContents = []
  }
  
  @objc func didRangeBeaconContents(notification: Notification) {
    if let userInfo = notification.userInfo {
        if let content = userInfo[XAMOOM_CONTENTS_KEY] {
            beaconContents = content as! [XMMContent]
        } else {
            BeaconNotificationHelper.isNotificationShown = [:]
        }
    }
  }
  
  func initizializeStartGrid() {
    elementTags = [nil]
    elementTypes = [DisplayType.Slider]
    tableView.reloadData()
    
    self.hideNothingFoundView()
    let loadingHud = MBProgressHUD.showAdded(to: self.view, animated: true)
    
    ApiHelper.shared.downloadContents(withTag: Globals.Tag.config, cursor: nil, desc: false) { (contents, cursor, hasMore) in
      loadingHud.hide(animated: true)
        
        if (self.isNeedToSendGeaogenseRequest) {
          self.downloadGeofenceRegions()
          self.isNeedToSendGeaogenseRequest = false
      }
      
      if let content = contents.first, let customMeta = content.customMeta {
        self.tableView.isHidden = false
        self.hideNothingFoundView()
        
        if self.nearbyContents.count > 0 {
          self.addNearby()
        }
        
        self.config = customMeta
        self.applyConfig(meta: customMeta)
        self.tableView.reloadData()
      } else {
        self.tableView.isHidden = true
        self.showNothingFoundView()
      }
    }
  }
  
  func showNothingFoundView() {
    if nothingFoundView == nil {
      let views = Bundle.main.loadNibNamed("NothingFoundView", owner: nil, options: nil)
      if let view = views?.first as? NothingFoundView {
        view.frame = self.view.bounds
        nothingFoundView = view
      }
    }
    
    guard let nothingFoundView = nothingFoundView else { return }
    self.view.addSubview(nothingFoundView)
    nothingFoundView.errorLabel.text = NSLocalizedString("error.nothing_found", comment: "")
  }
  
  func hideNothingFoundView() {
    nothingFoundView?.removeFromSuperview()
  }
  
  func applyConfig(meta: [AnyHashable:Any]) {
    var keys = Array(meta.keys) as! [String]
    keys.sort {$0.localizedStandardCompare($1) == .orderedAscending}
    let orderKeys = keys.compactMap {Int($0)}
    
    for key in orderKeys {
      let k = String(key)
      self.addHorizontalElement(tag: meta[k] as! String)
    }
  }
  
  func addHorizontalElement(tag: String) {
    elementTags.append(tag)
    elementTypes.append(.Horizontal)
  }
  
  func localizedElementName(fromTag tag: String) -> String? {
    let lang = ApiHelper.shared.deviceLanguage()
    var name: String? = nil

    let key = tag + "-" + lang
    name = config[key] as? String

    if name == nil {
      let key = tag + "-en"
      name = config[key] as? String
    }
    
    if name == nil {
      name = tag
    }
    
    return name
  }
  
  func addNearby() {
    let indexPath = IndexPath(row: 1, section: 0)
    
    if elementTypes.count > 1 && elementTypes[1] == .Nearby {
        tableView.reloadRows(at: [indexPath], with: .none)
      return
    }
    
    if !elementTypes.contains(.Nearby) {
      elementTypes.insert(.Nearby, at: 1)
      elementTags.insert(nil, at: 1)
      self.tableView.reloadData()
    }
  }
  
  func removeNearby() {
    if elementTypes.count > 1 {
      if elementTypes[1] != .Nearby {
        return
      }
      
      elementTypes.remove(at: 1)
      elementTags.remove(at: 1)
      self.tableView.reloadData()
    }
  }
    
    func downloadGeofenceRegions() {
        self.isGeofenceContentLoaded = false
        self.geofenceSpots = []
        self.monitoringRegions = []
        self.userActiveRegionContent = []
        self.nearbyContentsTemp = []
        ApiHelper.shared.downloadSpots(tags: [Globals.Tag.geofence], cursor: nil) { (spots, cursor, hasMore) in
            self.geofenceSpots = spots
            self.initGeofenceRegions()
        }
    }
    
    func initGeofenceRegions() {
        let myGroup = DispatchGroup()

        for spot in geofenceSpots {
            if let spotContent = spot.content {
                let distanceInMeters = currentLocation.distance(from: CLLocation(latitude: spot.latitude, longitude: spot.longitude))
                if let regionDiameter = spot.customMeta["diameter"] {
                    if let regionDiameterInt = Int(regionDiameter as! String) {
                        if (distanceInMeters <= Double(regionDiameterInt / 2)) {
                            if (geofenceSpotsSaved.contains(where: {$0.content.id as! String == spot.content.id as! String})) {
                                spot.content.title = geofenceSpotsSaved.filter({ $0.id as! String == spot.id as! String }).first?.content.title
                                spot.content.imagePublicUrl = geofenceSpotsSaved.filter({ $0.id as! String == spot.id as! String }).first?.content.imagePublicUrl
                                
                                let regionCenter = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
                                self.monitorRegionAtLocation(center: regionCenter, radius: regionDiameterInt / 2, identifier: spot.id as! String)
                            } else {
                                myGroup.enter()
                                ApiHelper.shared.downloadContent(withId: spotContent.id as! String, reason: .unknown, controller: self) {
                                    (content) in
                                  if let content = content {
                                    spot.content.title = content.title
                                    spot.content.imagePublicUrl = content.imagePublicUrl
                                      
                                    self.geofenceSpotsSaved.append(spot)

                                    let regionCenter = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
                                    self.monitorRegionAtLocation(center: regionCenter, radius: regionDiameterInt / 2, identifier: spot.id as! String)

                                  }
                                    myGroup.leave()
                                }
                            }
//                            spot.content.title = spot.name
//                            spot.content.imagePublicUrl = spot.image

//                            let regionCenter = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
//                            self.monitorRegionAtLocation(center: regionCenter, radius: regionDiameterInt / 2, identifier: spot.id as! String)
//                                myGroup.leave()
                        }
                    }
                }
            }
        }
        myGroup.notify(queue: .main) {
            self.isGeofenceContentLoaded = true
        }
    }
    
    func didClick(content: XMMContent) {
      didClick(content: content, isBeacon: false)
    }
    
    func didClick(content: XMMContent, isBeacon: Bool) {
      let controller = ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
      controller.isBeacon = isBeacon
      controller.content = content
      controller.hidesBottomBarWhenPushed = true
      navigationController?.pushViewController(controller, animated: true)
    }
    
    func removeEmptyCell(tag: String) {
      if elementTags.contains(tag) {
        let index = elementTags.index(of: tag) as! Int
        elementTags.remove(at: index)
        elementTypes.remove(at: index)
        
        if let _ = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
          self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
      }
    }
}

extension HomeViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    print("didSelect")
  }
}

extension HomeViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1;
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return elementTypes.count;
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?
    let type = elementTypes[indexPath.row] as DisplayType
    
    if type == .Slider {
      let sliderCell = tableView.dequeueReusableCell(withIdentifier:
        ImageSliderTableViewCell.identifier) as! ImageSliderTableViewCell
      sliderCell.delegate = self
      sliderCell.updateCell()
      cell = sliderCell
    } else if type == .Nearby {
      let horizontalCell = tableView.dequeueReusableCell(withIdentifier:
        HorizontalContentTableViewCell.identifier) as! HorizontalContentTableViewCell
      horizontalCell.title = NSLocalizedString("horizontalCell.title.nearby",
                                               comment: "Title when nearby contents are available")
      horizontalCell.type = .Nearby
      horizontalCell.beaconContents = nearbyContents.removingDuplicates(byKey: { $0.id as! String})
      horizontalCell.delegate = self
      cell = horizontalCell
    } else  {
      let horizontalCell = tableView.dequeueReusableCell(withIdentifier:
        HorizontalContentTableViewCell.identifier) as! HorizontalContentTableViewCell
      horizontalCell.title = localizedElementName(fromTag: elementTags[indexPath.row]!)
      horizontalCell.type = .Horizontal
      horizontalCell.contents = []
      horizontalCell.contentTag = elementTags[indexPath.row]
      horizontalCell.delegate = self
      cell = horizontalCell
    }
    
    return cell!
  }
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, radius: Int, identifier: String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            let region = CLCircularRegion(center: center,
                 radius: Double(radius), identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            locationManager.startMonitoring(for: region)
            monitoringRegions.append(region)
            locationManager.requestState(for: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            if let activeSpot = self.geofenceSpots.first(where: { $0.id as! String == identifier }) {
                if self.userActiveRegionContent.first(where: { $0.id as! String == activeSpot.content.id as! String }) != nil {
                } else {
                    self.userActiveRegionContent.append(activeSpot.content)
                }
                userActiveRegionContent.removeDuplicates()
                var tempContent: [XMMContent] = []
                tempContent.append(contentsOf: beaconContents)
                tempContent.append(contentsOf: userActiveRegionContent)
                nearbyContents = tempContent
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            if let activeSpot = self.geofenceSpots.first(where: { $0.id as! String == identifier }) {
                if let regionToRemove = self.userActiveRegionContent.first(where: { $0.id as! String == activeSpot.content.id as! String }) {
                    let indexToRemove = self.userActiveRegionContent.index(of: regionToRemove)!
                    self.userActiveRegionContent.remove(at: indexToRemove)
                }
                userActiveRegionContent.removeDuplicates()
                var tempContent: [XMMContent] = []
                tempContent.append(contentsOf: beaconContents)
                tempContent.append(contentsOf: userActiveRegionContent)
                nearbyContents = tempContent
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let identifier = region.identifier
        
        if (state == CLRegionState.inside) {
            if let activeSpot = self.geofenceSpots.first(where: { $0.id as! String == identifier }) {
                if self.userActiveRegionContent.first(where: { $0.id as! String == activeSpot.content.id as! String }) != nil {
                } else {
                    self.userActiveRegionContent.append(activeSpot.content)
                }
            }
        } else if (state == CLRegionState.outside) {
            if let activeSpot = self.geofenceSpots.first(where: { $0.id as! String == identifier }) {
                if let regionToRemove = self.userActiveRegionContent.first(where: { $0.id as! String == activeSpot.content.id as! String }) {
                    let indexToRemove = self.userActiveRegionContent.index(of: regionToRemove)!
                    self.userActiveRegionContent.remove(at: indexToRemove)
                }
            }
        }
        
        var content: [XMMContent] = []
        content.append(contentsOf: beaconContents)
        content.append(contentsOf: userActiveRegionContent)
        nearbyContentsTemp.append(contentsOf: content)
        
        if self.isGeofenceContentLoaded {
            nearbyContentsTemp.removeDuplicates()
            self.nearbyContents = self.nearbyContentsTemp
        }
    }
    
    func stopMonitoringRegions() {
        for region in monitoringRegions {
            stopMonitoring(region: region)
        }
        monitoringRegions = []
    }
    
    func stopMonitoring(region: CLRegion) {
      for region in locationManager.monitoredRegions {
        locationManager.stopMonitoring(for: region)
      }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringVisits()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingHeading()
        initGeofenceRegions()
    }
    
    func stopUpdatingLocation() {
        stopMonitoringRegions()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }
}
