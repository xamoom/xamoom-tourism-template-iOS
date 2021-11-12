//
//  ScanViewController.swift
//  tourismtemplate
//
//  Created by Thomas Krainz-Mischitz on 17.01.19.
//  Copyright © 2019 xamoom GmbH. All rights reserved.
//

import UIKit
import CoreNFC
import AVFoundation
import QRCodeReader

class ScanViewController: UIViewController {
  
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var scanButton: UIButton!
  @IBOutlet weak var imageTopConstaint: NSLayoutConstraint!
  @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var permissionView: UIView!
  @IBOutlet weak var permissionLabel: UILabel!
  @IBOutlet weak var settingsButton: UIButton!
  @IBOutlet weak var readerHintView: UIView!
  @IBOutlet weak var readerHintLabel: UILabel!
  
  var inAppNotificationHelper: InAppNotificationHelper?
  
  var nfcEnabled = false
  var didScanAction: ((String, ScanType) -> Void)?
  
  lazy var readerVC: QRCodeReaderViewController = {
    let objectTypes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.interleaved2of5, AVMetadataObject.ObjectType.aztec,
                       AVMetadataObject.ObjectType.dataMatrix, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.code128,
                       AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.ean13,
                       AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.itf14]
    let builder = QRCodeReaderViewControllerBuilder {
      $0.reader = QRCodeReader(metadataObjectTypes: objectTypes, captureDevicePosition: .back)
      $0.showCancelButton = false
    }
    return QRCodeReaderViewController(builder: builder)
  }()
  
  @available(iOS 11.0, *)
  lazy var nfcHelper: NFCHelper = {
    return NFCHelper()
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Scan screen")
    permissionView.isHidden = false
    permissionLabel.isHidden = true
    settingsButton.isHidden = true
    settingsButton.layer.cornerRadius = 10
    
    hideHintLabel()
    
    checkNFC()
    
    permissionLabel.text = NSLocalizedString("scanViewController.permission", comment: "")
    settingsButton.setTitle(NSLocalizedString("scanViewController.open.settings", comment: ""), for: .normal)
    
    scanButton.layer.cornerRadius = 10
    
    inAppNotificationHelper = InAppNotificationHelper()
    inAppNotificationHelper?.view = UIApplication.shared.windows.first
    descriptionLabel.text = NSLocalizedString("scanViewController.nfc.label", comment: "")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.restartQRScanner()
    if let controller = self.navigationController {
      showNavigationBar(navController: controller)
      if Globals.isBackgroundImage.elementsEqual("true") {
             controller.navigationBar.setBackgroundImage(UIImage(named: "background_image"), for: .default)
      }
    }
    
    if nfcEnabled {
      let segmentedControl = UISegmentedControl(items: ["QR", "NFC"])
      segmentedControl.selectedSegmentIndex = 0
      segmentedControl.addTarget(self, action: #selector(segmentSelected(sender:)), for: .valueChanged)
      navigationItem.titleView = segmentedControl
    } else {
      navigationItem.title = NSLocalizedString("scanViewController.title", comment: "")
    }
    
    checkPermission()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    AnalyticsHelper.reportContentView(contentName: "Scan",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: "",
                                      customAttributes: nil)
  }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 15.0, *) {
            let appearanceStandart = UINavigationBarAppearance()
            appearanceStandart.configureWithOpaqueBackground()
            appearanceStandart.backgroundColor = Globals.Color.primaryColor
            appearanceStandart.shadowColor = .clear
            let appearanceScroll = UINavigationBarAppearance()
            appearanceScroll.configureWithOpaqueBackground()
            appearanceScroll.backgroundColor = nil
            appearanceScroll.shadowColor = .clear
            self.navigationController?.navigationBar.standardAppearance = appearanceStandart
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearanceScroll
        }
    }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func restartQRScanner() {
    readerVC.startScanning()
  }
  
  func test() {
    inAppNotificationHelper?.showNotification(message: NSLocalizedString("sideMenuViewController.scan.error", comment: ""))
  }
  
  @objc func segmentSelected(sender: UISegmentedControl) {
    let index = sender.selectedSegmentIndex
    
    if index == 0 {
      addQRToView()
    } else {
      self.descriptionLabel.text = NSLocalizedString("scanViewController.nfc.label", comment: "")
      readerVC.view.removeFromSuperview()
      readerVC.removeFromParentViewController()
      startNfcScanning()
    }
  }
  
  @IBAction func didTapScan(_ sender: Any) {
    startNfcScanning()
  }
  
  private func addQRToView() {
    addChildViewController(readerVC)
    view.addSubview(readerVC.view)
    view.addSubview(readerHintView)
    readerHintView.isHidden = true
    readerVC.didMove(toParentViewController: self)
  }
  
  private func checkPermission() {
    let authorizationSatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    switch authorizationSatus {
    case .denied:
      permissionView.isHidden = false
      permissionLabel.isHidden = false
      settingsButton.isHidden = false
      self.navigationItem.titleView?.isHidden = true
      break
    case .authorized:
      permissionView.isHidden = true
      self.navigationItem.titleView?.isHidden = false
      
      readerVC.completionBlock = { (result: QRCodeReaderResult?) in
        if let result = result {
          if self.didScanAction != nil {
            self.didScanAction!(result.value, ScanType.QR)
            self.navigationController?.popViewController(animated: true)
            return
          }
          if result.metadataType == "org.iso.QRCode" {
            self.qrScaningResultHandler(result: result.value)
          } else {
            self.codeScaningResultHandler(result: result.value)
          }
        }
      }
      
      addQRToView()
      break
    default:
      AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
        if granted == false {
          DispatchQueue.main.async {
            self.permissionView.isHidden = false
            self.permissionLabel.isHidden = false
            self.settingsButton.isHidden = false
            self.navigationItem.titleView?.isHidden = true
          }
        } else {
          DispatchQueue.main.async {
            self.permissionView.isHidden = true
            self.navigationItem.titleView?.isHidden = false
            
            self.addQRToView()
            self.readerVC.completionBlock = { (result: QRCodeReaderResult?) in
              if let result = result {
                if self.didScanAction != nil {
                  self.didScanAction!(result.value, ScanType.QR)
                  self.navigationController?.popViewController(animated: true) //pushViewController(vc, animated: true)
                  return
                }
                if result.metadataType == "org.iso.QRCode" {
                  self.qrScaningResultHandler(result: result.value)
                } else {
                  self.codeScaningResultHandler(result: result.value)
                }
              }
            }
          }
        }
      })
    }
  }
  
  private func showHintLabel() {
    readerHintView.isHidden = false
    readerHintLabel.text = NSLocalizedString("scanViewController.code.label.failed", comment: "")
  }
  
  private func hideHintLabel() {
    readerHintView.isHidden = true
  }
  
  private func codeScaningResultHandler(result: String) {
    self.hideHintLabel()
    
    var host = ""
    if let path = Bundle.main.path(forResource: "gen", ofType: "plist"),
      let myDict = NSDictionary(contentsOfFile: path) {
      host = myDict["custom-webclient-host"] as! String
    }
    
    self.readerVC.stopScanning()
    
    let url = URL(string: result)
    let urlHost = url?.host
    let urlPath = url?.path
    
    if urlHost == nil {
      let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
      vc.locId = result
      vc.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(vc, animated: true)
    }
  }
  
  private func qrScaningResultHandler(result: String) {
    
    self.hideHintLabel()
    
    var host = ""
    if let path = Bundle.main.path(forResource: "gen", ofType: "plist"),
      let myDict = NSDictionary(contentsOfFile: path) {
      host = myDict["custom-webclient-host"] as! String
    }
    
    self.readerVC.stopScanning()
    
    let url = URL(string: result)
    let urlHost = url?.host
    let urlPath = url?.path
    
    if let urlHost = urlHost {
      if urlHost == host && (urlPath == nil || urlPath == "" || urlPath == "/") {
        
        let controller = HomeViewController(nibName: "HomeViewController", bundle: Bundle.main)
        controller.hidesBottomBarWhenPushed = false
        let appDelegate  = UIApplication.shared.delegate as! AppDelegate
        let tabCon = appDelegate.window!.rootViewController as! UITabBarController
        tabCon.selectedIndex = 0
        let navcon = tabCon.selectedViewController as! UINavigationController
        navcon.pushViewController(controller, animated: true)
      } else if urlHost == host && urlPath != nil && urlPath!.contains("content/") {
        if let contentId = self.locationIdFrom(urlString: result) {
            let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
            vc.contentId = contentId
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
      } else if urlHost == host && urlPath != nil && urlPath!.contains("/") {
        if let locId = self.locationIdFrom(urlString: result) {
            let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
            vc.locId = locId
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
      } else if urlHost == "xm.gl" || urlHost == "r.xm.gl" {
        if urlPath != nil && urlPath!.contains("content/") {
          if let contentId = self.locationIdFrom(urlString: result) {
            let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
            vc.contentId = contentId
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
          } else {
            self.showHintLabel()
            self.restartQRScanner()
          }
        } else if urlPath != nil && urlPath!.contains("/") {
          if let locId = self.locationIdFrom(urlString: result) {
            let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
            vc.locId = locId
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
          } else {
            self.showHintLabel()
            self.restartQRScanner()
          }
        }
      } else {
        self.showHintLabel()
        self.restartQRScanner()
      }
    } else {
      let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
      vc.locId = result
      vc.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(vc, animated: true)
    }
  }
  
  func handleResultString(result: String) {
    self.hideHintLabel()
    var host = ""
    if let path = Bundle.main.path(forResource: "gen", ofType: "plist"),
      let myDict = NSDictionary(contentsOfFile: path) {
      host = myDict["custom-webclient-host"] as! String
    }
    self.readerVC.stopScanning()
    
    var contentId: String? = nil
    var locationIdentifier: String? = nil
    var openHome = false
    
    let url = URL(string: result)
    let urlHost = url?.host
    let urlPath = url?.path
    
    if let urlHost = urlHost {
      if urlHost == host && (urlPath == nil || urlPath == "" || urlPath == "/") {
        openHome = true
      } else if urlHost == host && urlPath != nil && urlPath!.contains("content/") {
        contentId = self.locationIdFrom(urlString: result)
      } else if urlHost == host && urlPath != nil && urlPath!.contains("/") {
        locationIdentifier = self.locationIdFrom(urlString: result)
      } else if urlHost == "xm.gl" || urlHost == "r.xm.gl" {
        if urlPath != nil && urlPath!.contains("content/") {
          contentId = self.locationIdFrom(urlString: result)
        } else if urlPath != nil && urlPath!.contains("/") {
          locationIdentifier = self.locationIdFrom(urlString: result)
        }
      } else {
        locationIdentifier = result
      }
    } else {
      locationIdentifier = result
    }
    
    if openHome == true {
      let controller = HomeViewController(nibName: "HomeViewController", bundle: Bundle.main)
      controller.hidesBottomBarWhenPushed = false
      let appDelegate  = UIApplication.shared.delegate as! AppDelegate
      let tabCon = appDelegate.window!.rootViewController as! UITabBarController
      tabCon.selectedIndex = 0
      let navcon = tabCon.selectedViewController as! UINavigationController
      navcon.pushViewController(controller, animated: true)
    }  else if let contentId = contentId {
      
      let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
      vc.contentId = contentId
      vc.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(vc, animated: true)
      
    } else if let locationIdentifier = locationIdentifier {
      let vc = ContentViewController(nibName: "ContentViewController", bundle: nil)
      vc.locId = locationIdentifier
      vc.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(vc, animated: true)
    } else {
      self.descriptionLabel.text = NSLocalizedString("scanViewController.nfc.label.failed", comment: "")
    }
  }
  
  private func startNfcScanning() {
    if #available(iOS 11.0, *) {
      nfcHelper.startNFCScanning()
      animateNfcImage()
      
      nfcHelper.onNFCResult = { (nfcString, error) in
        DispatchQueue.main.async {
          self.resetNfcImage()
          
          if let result = nfcString {
            if self.didScanAction != nil {
              self.didScanAction!(result, ScanType.NFC)
            } else {
              self.handleResultString(result: result)
            }
          }
        }
      }
    }
  }
  
  func testHome() {
    let controller = HomeViewController(nibName: "HomeViewController", bundle: Bundle.main)
    controller.hidesBottomBarWhenPushed = false
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate
    let tabCon = appDelegate.window!.rootViewController as! UITabBarController
    tabCon.selectedIndex = 0
    let navcon = tabCon.selectedViewController as! UINavigationController
    navcon.pushViewController(controller, animated: false)
  }
  
  private func animateNfcImage() {
    view.layoutIfNeeded()
    
    UIView.animate(withDuration: 0.5) {
      self.imageTopConstaint.constant = 20
      self.imageHeightConstraint.constant = 120
      self.view.layoutIfNeeded()
    }
  }
  
  private func resetNfcImage() {
    view.layoutIfNeeded()
    
    UIView.animate(withDuration: 0.5) {
      self.imageTopConstaint.constant = 120
      self.imageHeightConstraint.constant = 200
      self.view.layoutIfNeeded()
    }
  }
  
  private func checkNFC() {
    if #available(iOS 11.0, *) {
      if NFCNDEFReaderSession.readingAvailable {
        self.nfcEnabled = true
      }
    }
  }
  
  private func showNavigationBar(navController: UINavigationController) {
    
    navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor:Globals.Color.tabbarSelected]
    
    navigationController?.navigationBar.tintColor = Globals.Color.tabbarSelected
    navigationController?.navigationBar.setBackgroundImage(nil,
                                                                for: .default)
    navigationController?.navigationBar.shadowImage = nil
    navigationController?.navigationBar.isTranslucent = true
      
      if #available(iOS 15.0, *) {
          let appearance = UINavigationBarAppearance()
          appearance.configureWithOpaqueBackground()
          appearance.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
          self.navigationController?.navigationBar.standardAppearance = appearance
          self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
      }
    UIApplication.shared.statusBarStyle = Globals.Color.barFontColor.isDark ? .default : .lightContent
  }
  
  @IBAction func openSettings(_ sender: Any) {
    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
      return
    }
    
    if UIApplication.shared.canOpenURL(settingsUrl) {
      if #available(iOS 10.0, *) {
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
      } else {
        // Fallback on earlier versions
      }
    }
  }
  
  private func locationIdFrom(urlString: String) -> String? {
    let url = URL(string: urlString)
    if let url = url {
      return url.lastPathComponent
    }
    
    return nil
  }
}

