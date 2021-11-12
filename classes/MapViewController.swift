//
//  MapViewController.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 21/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import MapKit
import XamoomSDK
import MBProgressHUD
import Mapbox

class MapViewController: UIViewController {
  let mapDetailHeight: CGFloat = 210.0
  
  @IBOutlet weak var mapView: MGLMapView!
  @IBOutlet weak var centerUserButton: UIButton!
  @IBOutlet weak var centerBoundsButton: UIButton!
  @IBOutlet weak var centerBoundsButtonBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var centerUserLocationImageView: UIImageView!
  @IBOutlet weak var centerSpotBoundsImageView: UIImageView!
  
  var mapMarker: UIImage?
  var orientations: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
  var filterViewController: FilterViewController?
  var mapTapRecognizer: UITapGestureRecognizer?
  var mapCenterBottomConstraint: NSLayoutConstraint?
  var mapDetailSwipeRecognizer: UISwipeGestureRecognizer?
  var mapDetailBottomConstraint: NSLayoutConstraint?
  var mapDetailView: MapDetailView?
  var spots: [XMMSpot] = []
  var annotations: [MGLAnnotation] = []
  var shouldReloadSpot = true
  var isLocationGranted: Bool = true
  var userLocation : CLLocation? {
    didSet {
      didUpdateUserLocationButtonIcon()
      updateUserlocationInAnnotations()
    }
  }
  var isLoading = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCenterButton()
    setupMapView()
    setupMapDetailView()
    
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Map screen")
    AnalyticsHelper.reportContentView(contentName: "Map",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: "",
                                      customAttributes: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.isNavigationBarHidden = true
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(didUpdateLocation(notification:)),
                   name: NSNotification.Name(rawValue: LOCATION_UPDATE),
                   object: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    reloadView()
    
    NotificationCenter.default.addObserver(self, selector:#selector(reloadView), name: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    NotificationCenter.default
      .removeObserver(self,
                      name: NSNotification.Name(rawValue: LOCATION_UPDATE),
                      object: nil)
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @objc func didUpdateLocation(notification: NSNotification) {
    self.userLocation = notification.userInfo?["location"] as? CLLocation;
    self.mapView.showsUserLocation = self.userLocation != nil
    
    if let _ = self.userLocation {
      self.didUpdateUserLocationButtonIcon()
    }
  }
  
  func didUpdateUserLocationButtonIcon() {
    let authStatus = CLLocationManager.authorizationStatus()
    var color = UIColor(hex: "#393939")
    
    if let image = centerSpotBoundsImageView?.image {
      centerSpotBoundsImageView.image = image.imageWithColor(color1: color)
    }
    
    if (authStatus == .denied || authStatus == .notDetermined || authStatus == .restricted) || self.userLocation == nil {
      color = UIColor(hex: "#D3D3D3")
    }
    if let image = centerUserLocationImageView?.image {
      centerUserLocationImageView.image = image.imageWithColor(color1: color)
    }
  }
  
  @objc func reloadView() {
    let locationHelper = ApiHelper.shared.locationHelper
    userLocation = locationHelper.userLocation
    
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .denied || authStatus == .notDetermined || authStatus == .restricted {
      self.isLocationGranted = false
    } else {
      self.isLocationGranted = true
    }
    didUpdateUserLocationButtonIcon()
    
    if shouldReloadSpot {
      closeMapDetail()
      self.spots.removeAll()
      downloadSpots(cursor: nil)
    }
    
    shouldReloadSpot = true
  }
  
  func setupMapView() {
    
    mapView.delegate = self
    mapTapRecognizer = UITapGestureRecognizer(target: self,
                                              action: #selector(closeMapDetail))
    view.addGestureRecognizer(mapTapRecognizer!)
  }
  
  func setupCenterButton() {
    if #available(iOS 11.0, *) {
      self.mapCenterBottomConstraint = NSLayoutConstraint(item: view.safeAreaLayoutGuide,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: centerBoundsButton,
                                                          attribute: .bottom,
                                                          multiplier: 1.0,
                                                          constant: 20)
    } else {
      var constant = CGFloat(20)
      if let tabBarHeight = self.tabBarController?.tabBar.frame.size.height {
        constant += tabBarHeight
      }
      self.mapCenterBottomConstraint = NSLayoutConstraint(item: view,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: centerBoundsButton,
                                                          attribute: .bottom,
                                                          multiplier: 1.0,
                                                          constant:constant)
    }
    
    view.addConstraint(mapCenterBottomConstraint!)
    view.setNeedsLayout()
  }
  
  func setupMapDetailView() {
    mapDetailView = MapDetailView(frame: CGRect.zero)
    
    guard let mapDetailView = mapDetailView else {
      return
    }
    
    mapDetailView.delegate = self
    mapDetailView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(mapDetailView)
    
    var constraints: [NSLayoutConstraint] = []
    if #available(iOS 11.0, *) {
      mapDetailBottomConstraint = NSLayoutConstraint(item: mapDetailView,
                                                     attribute: .bottom,
                                                     relatedBy: .equal,
                                                     toItem: view.safeAreaLayoutGuide,
                                                     attribute: .bottom,
                                                     multiplier: 1.0,
                                                     constant: mapDetailHeight)
    } else {
      mapDetailBottomConstraint = NSLayoutConstraint(item: mapDetailView,
                                                     attribute: .bottom,
                                                     relatedBy: .equal,
                                                     toItem: view,
                                                     attribute: .bottom,
                                                     multiplier: 1.0,
                                                     constant: mapDetailHeight)
    }
    constraints.append(mapDetailBottomConstraint!)
    constraints.append(NSLayoutConstraint(item: mapDetailView,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .leading,
                                          multiplier: 1.0,
                                          constant: 0))
    constraints.append(NSLayoutConstraint(item: mapDetailView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .trailing,
                                          multiplier: 1.0,
                                          constant: 0))
    constraints.append(NSLayoutConstraint(item: mapDetailView,
                                          attribute: .height,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1.0,
                                          constant: mapDetailHeight))
    
    view.addConstraints(constraints)
    mapDetailSwipeRecognizer =
      UISwipeGestureRecognizer(target: self,
                               action: #selector(mapDetailSwipe(gesture:)))
    mapDetailSwipeRecognizer?.direction = .down
    mapDetailView.addGestureRecognizer(mapDetailSwipeRecognizer!)
  }
  
  @objc func mapDetailSwipe(gesture: UIPanGestureRecognizer) {
    closeMapDetail()
  }
  
  func openMapDetail() {
    if #available(iOS 11.0, *) {
      self.mapDetailBottomConstraint?.constant = view.safeAreaInsets.top
    } else {
      self.mapDetailBottomConstraint?.constant = 0
    }
    
    self.centerBoundsButtonBottomConstraint.constant = 252

    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  @objc func closeMapDetail() {
    let annotations = mapView.selectedAnnotations
    for annotation in annotations {
      mapView.deselectAnnotation(annotation, animated: true)
    }
    
    self.centerBoundsButtonBottomConstraint.constant = 90

    self.mapDetailBottomConstraint?.constant = self.mapDetailHeight
    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  func downloadSpots(cursor: String?) {
    
    self.isLoading = true

    if let annotations = mapView.annotations {
      mapView.removeAnnotations(annotations)
    }
    
    if(cursor == nil){
      spots.removeAll()
    }
    
    let loadingHud = MBProgressHUD.showAdded(to: self.view, animated: true)
    
    ApiHelper.shared.downloadSpots(tags: ["map", "MAP"], cursor: cursor) {
      (spots, cursor, hasMore) in
      loadingHud.hide(animated: true)
      
      self.spots.append(contentsOf: spots)
      
      if hasMore {
        self.downloadSpots(cursor: cursor)
      } else {
        self.displaySpots(spots: self.spots)
        self.isLoading = false
      }
    }
  }
  
  func displaySpots(spots: [XMMSpot]) {
    if (mapMarker == nil && isMarkerLoaded() == false) {
      mapMarker = UIImage(named: "mapmarker")
    } else {
      mapMarker = mapMarkerFromBase64()
    }
    
    self.mapView.removeAnnotations(annotations)
    annotations.removeAll()
    for spot in spots {
      annotations.append(MapAnnotation(spot: spot, userLocation: self.userLocation))
    }
      
    self.mapView.addAnnotations(annotations)
    
    if annotations.count > 1 {
      centerSpotBounds()
    } else if annotations.count == 1 {
      moveMapTo(coordinates: annotations[0].coordinate)
    } else{
      centerMapOnUserLocation()
    }
  }
  
  func getDegreeOffsetForMarkers(max: Double, min: Double, markserSize: CGFloat) -> Double {
        let mapViewWidth = self.mapView.frame.size.width
        let widthDegress = max - min
        let degreesPerPixel = CGFloat(widthDegress) / mapViewWidth
        return Double(degreesPerPixel * markserSize)
  }
  
  func centerSpotBounds() {
    var latArray: [Double] = []
    var lonArray: [Double] = []
    for location in self.spots {
      latArray.append(location.latitude as Double)
      lonArray.append(location.longitude as Double)
    }
    
    if latArray.isEmpty || lonArray.isEmpty {
      centerMapOnUserLocation()
      return
    }
    
    let maxLat = latArray.max()!
    let minLat = latArray.min()!
    
    let maxLon = lonArray.max()!
    let minLon = lonArray.min()!
    
    let latOffset = getDegreeOffsetForMarkers(max: maxLat, min: minLat, markserSize: self.mapMarker?.size.width ?? 45)
    let lonOffset = getDegreeOffsetForMarkers(max: maxLon, min: minLon, markserSize: self.mapMarker?.size.height ?? 45)

    let ne = CLLocationCoordinate2DMake(minLat - latOffset, minLon - lonOffset)
    let sw = CLLocationCoordinate2DMake(maxLat + latOffset, maxLon + lonOffset)
    let bounds = MGLCoordinateBoundsMake(sw, ne)
    self.mapView.visibleCoordinateBounds = bounds
  }
  
  func isMarkerLoaded() -> Bool {
    if (ApiHelper.shared.system == nil) {
      ApiHelper.shared.downloadSystem(completion: { (system) -> (Void) in
        
        if let system = system {
          self.downloadStyle(system: system)
          ApiHelper.shared.downloadStyle(system: system, completion: { (style) -> (Void) in
            if let annotations = self.mapView.annotations {
              self.mapView.removeAnnotations(annotations)
            }
            self.displaySpots(spots: self.spots)
          })
        }
      })
      return false
    } else if (ApiHelper.shared.style == nil) {
      if let system = ApiHelper.shared.system {
        downloadStyle(system: system)
      }
    }
    
    return true
  }
  
  func mapMarkerFromBase64() -> UIImage {
    let base64: String? = ApiHelper.shared.style?.customMarker
    var marker: UIImage?
    
    if let base64 = base64 {
      if base64.contains("data:image/svg") {
        let cleanBase64 = base64.replacingOccurrences(of: "data:image/svg+xml;base64,", with: "")
        let data = NSData(base64Encoded: cleanBase64, options: NSData.Base64DecodingOptions(rawValue: UInt(0)))
        if let data = data {
          let svgMarker = JAMSVGImage(svgData: data as Data!)
          marker = svgMarker?.image()
        }
      } else {
        let range = base64.range(of: "base64,")
        
        if let range = range {
          let newRange = base64.startIndex...base64.index(range.upperBound, offsetBy: -1)
          
          var cleanBase64 = base64
          cleanBase64.removeSubrange(newRange)
          let data = NSData(base64Encoded: cleanBase64, options: NSData.Base64DecodingOptions(rawValue: UInt(0)))
          marker = UIImage(data: data! as Data)
        }
      }
    }
    
    if let marker = marker {
      return marker.resizeImage(newWidth: 30)
    } else {
      return UIImage(named: "mapmarker")!
    }
  }
  
  func downloadStyle(system: XMMSystem) {
    ApiHelper.shared.downloadStyle(system: system , completion: { (style) -> (Void) in
      
      if let annotations = self.mapView.annotations {
        self.mapView.removeAnnotations(annotations)
      }
      self.displaySpots(spots: self.spots)
    })
  }
  
  func updateUserlocationInAnnotations() {
    guard let annotations = self.mapView.annotations else {
      return
    }
    for annotation in annotations {
      if annotation.isKind(of: MapAnnotation.self) {
        let mapAnnotation = annotation as! MapAnnotation
        mapAnnotation.userLocation = userLocation
      }
    }
  }
  
  func centerMapOnUserLocation() {
    if let userLocation = userLocation {
      moveMapTo(coordinates: userLocation.coordinate)
    }
  }
  
  func moveMapTo(coordinates: CLLocationCoordinate2D) {
    if let annotations = self.mapView.annotations {
      self.mapView.setCenter(coordinates, zoomLevel: 16, animated: true)
    }
  }
  
  @IBAction func didClickCenter(_ sender: Any) {
    if !CLLocationManager.locationServicesEnabled() || !self.isLocationGranted {
      let alert = UIAlertController(title: NSLocalizedString("mapviewcontroller.no.permission.title", comment: ""),
                                    message: NSLocalizedString("mapviewcontroller.no.permission.message", comment: ""),
                                    preferredStyle: .alert)
      
      let settingsAction = UIAlertAction(title: NSLocalizedString("mapviewcontroller.alert.settings", comment: ""), style: .default) { (action) in
        self.openSettings()
      }
      let cancelAction = UIAlertAction(title: NSLocalizedString("mapviewcontroller.alert.cancel", comment: ""), style: .default, handler: nil)
      alert.addAction(settingsAction)
      alert.addAction(cancelAction)
      self.present(alert, animated: true, completion: nil)
      return
    }
    
    if self.userLocation == nil {
      let alert = UIAlertController(title: NSLocalizedString("mapviewcontroller.no.location.title", comment: ""),
                                    message: NSLocalizedString("mapviewcontroller.no.location.message", comment: ""),
                                    preferredStyle: .alert)
      
      let settingsAction = UIAlertAction(title: NSLocalizedString("mapviewcontroller.alert.settings", comment: ""), style: .default) { (action) in
          //openSettings()
      }
      let cancelAction = UIAlertAction(title: NSLocalizedString("mapviewcontroller.alert.cancel", comment: ""), style: .default, handler: nil)
      alert.addAction(settingsAction)
      alert.addAction(cancelAction)
      self.present(alert, animated: true, completion: nil)
      return
    }
    
    centerMapOnUserLocation()
  }
  
  @IBAction func didClickCenterBounds(_ sender: Any) {
    centerSpotBounds()
    closeMapDetail()
  }
  
  func openSettings() {
    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
      return
    }
    
    if UIApplication.shared.canOpenURL(settingsUrl) {
      if #available(iOS 10.0, *) {
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
      }
    }
  }
}

extension MapViewController : MGLMapViewDelegate {
  
  func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
    if annotation.isKind(of: MapAnnotation.self) {
      let mapAnnotation = annotation as! MapAnnotation
      mapDetailView?.spot = mapAnnotation.spot
      moveMapTo(coordinates: CLLocationCoordinate2D(latitude: mapAnnotation.spot.latitude, longitude: mapAnnotation.spot.longitude))
      openMapDetail()
    }
  }
  
  func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
    closeMapDetail()
  }
  
  func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
    guard let annotationImage = self.mapView.dequeueReusableAnnotationImage(withIdentifier: "identifier") else {
      var image = UIImage.init(named: "mapmarker")
      
      if let mapMarker = self.mapMarker {
        image = mapMarker
      }
      
      return MGLAnnotationImage(image: image!, reuseIdentifier: "identifier")
    }
    
    return annotationImage
  }
}

extension MapViewController : MapDetailViewDelegate {
  func openContent(content: XMMContent) {
    let controller = ContentViewController(nibName: "ContentViewController",
                                           bundle: Bundle.main)
    controller.contentId = content.id as? String
    controller.hidesBottomBarWhenPushed = true
    navigationController?.pushViewController(controller, animated: true)
    shouldReloadSpot = false
  }
}
