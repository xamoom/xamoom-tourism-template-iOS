//
//  ContentViewController.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 20/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import MBProgressHUD

class ContentViewController: UIViewController, ContentViewControllerProtocol, XMMContentBlocksDelegate {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var headerImage: UIImageView!
  
  var savedTitle: String?
  var content: XMMContent?
  var tag: String?
  var contentId: String?
  var contentBlocks: XMMContentBlocks?
  var locId: String?
  var initialHeaderRect: CGRect?
  var headerView: UIView?
  var topBarOffset: CGFloat!
  var nothingFoundView: NothingFoundView?
  var isBeacon = false
  var tableHeaderView: ContentTableHeaderView?
  var shareButton: UIBarButtonItem?
  
  var reloadContent = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    ApiHelper.shared.downloadSystem(completion: nil)
    
    var analyticsContentId = "";
    if let contentId = contentId {
      analyticsContentId = contentId
    } else if let content = content {
      analyticsContentId = content.id as! String
    } else if let locId = locId {
      analyticsContentId = locId
    } else {
      analyticsContentId = tag!
    }
    
    AnalyticsHelper.reportContentView(contentName: "Content",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: analyticsContentId,
                                      customAttributes: nil)
    
    savedTitle = self.navigationItem.title
    hideNavigationBar()
    
    contentBlocks = XMMContentBlocks(tableView: tableView,
                                     api: ApiHelper.shared.api)

    contentBlocks?.delegate = self
    contentBlocks?.navController = self.navigationController
    
    var internalUrls: [String] = []
    
    if let dictionary = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "gen", ofType: "plist")!) {
      if let array = dictionary["urls"] as? [String] {
        internalUrls = array
      }
    }
    
    var nonInternalUrls: [String] = []
    
    if let dictionary = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "gen", ofType: "plist")!) {
      if let array = dictionary["non-internal-urls"] as? [String] {
        nonInternalUrls = array
      }
    }
    
    
    
    contentBlocks?.internalUrls = internalUrls
    contentBlocks?.nonInternalUrls = nonInternalUrls
    contentBlocks?.webViewNavigationBarTintColor = Globals.Color.tabbarSelected
    contentBlocks?.chromeColor = ApiHelper.shared.style?.chromeHeaderColor
    
    let navigationWay = UserDefaults.standard.integer(forKey: Globals.Settings.navigationKey) as NSNumber
    contentBlocks?.navigationType = navigationWay

    tableView.delegate = self
    tableView.dataSource = contentBlocks
    
    topBarOffset = UIApplication.shared.statusBarFrame.size.height + (navigationController?.navigationBar.frame.size.height)!
    
    setupHeaderView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.isNavigationBarHidden = false
    if reloadContent == true {
    contentBlocks?.viewWillAppear()
    
    if let content = content {
      if let id = content.id {
        downloadContent(contentId: id as! String)
      }
    }
    
    if let tag = tag {
      downloadContent(with: tag)
    }
    
    if let contentId = contentId {
      downloadContent(contentId: contentId)
    }
    
    if let locId = locId {
      downloadContent(locId: locId)
    }
    
    setupContentOffset()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    updateHeaderHeight()
    showHeaderImage(imageUrl: content?.imagePublicUrl)
    
    let contentViewedNumber = UserDefaults.standard.integer(forKey: Globals.Settings.contentNumberViewed)
    if (contentViewedNumber == 2) {
        PushNotificationHelper.requestNotificationAuthorization {}
    }
    if (contentViewedNumber <= 2) {
        UserDefaults.standard.set(contentViewedNumber + 1, forKey: Globals.Settings.contentNumberViewed)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    contentBlocks?.viewWillDisappear()
    NotificationCenter.default.removeObserver(self)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidLayoutSubviews() {
    updateHeaderHeight()
  }
  
  func setupHeaderView() {
    
    initialHeaderRect = headerImage.frame
    tableView.tableHeaderView = nil

    let tableHeaderView : ContentTableHeaderView = UIView.fromNib()
    
    tableHeaderView.releaseActionView.layer.cornerRadius = 4.0
    tableHeaderView.releaseActionView.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
    
    tableView.addSubview(tableHeaderView)
    self.tableHeaderView = tableHeaderView
    
    if UserDefaults.standard.bool(forKey: Globals.Settings.isSocialSharingEnabled) {
          self.tableHeaderView?.addShareButton()
          self.tableHeaderView?.shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

  }
  
  func setupContentOffset() {
    if let height = initialHeaderRect?.size.height {
      tableView.contentInset = UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
      tableView.contentOffset = CGPoint(x: 0, y: -height)
    }
  }
  
  func showNavigationBar() {
    self.navigationItem.title = savedTitle
    self.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor:Globals.Color.tabbarSelected]
    
    self.navigationController?.navigationBar.tintColor = Globals.Color.tabbarSelected
    self.navigationController?.navigationBar.setBackgroundImage(nil,
                                                                for: .default)
    self.navigationController?.navigationBar.shadowImage = nil
    self.navigationController?.navigationBar.isTranslucent = true
    UIApplication.shared.statusBarStyle = Globals.Color.barFontColor.isDark ? .default : .lightContent
    if Globals.isBackgroundImage.elementsEqual("true") {
      self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "background_image"), for: .default)
    }
    if UserDefaults.standard.bool(forKey: Globals.Settings.isSocialSharingEnabled) {
          shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
          self.navigationItem.rightBarButtonItem = shareButton
    }
  }
      
  @objc func shareTapped() {
    var itemsToShare: [URL]
    if let sharingUrl = self.content?.sharingUrl {
      if (sharingUrl.isEmpty) {
        generateSharingUrlAndOpen()
      } else {
        itemsToShare = [URL(string: sharingUrl)!]
        let ac = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        present(ac, animated: true)
      }
    } else {
      generateSharingUrlAndOpen()
    }
        
  }
  
  func generateSharingUrlAndOpen() {
    var itemsToShare: [URL]
    var genPlist: NSDictionary?
    if let path =  Bundle.main.path(forResource: "gen",
                                    ofType: "plist") {
      genPlist = NSDictionary(contentsOfFile: path)
    }
      
    var url: String?
    if let webClientHost = genPlist?.object(forKey: "custom-webclient") as? String {
        url = webClientHost
        url?.append("/content/" + (content?.id as! String))
    }
      
    if let safeUrl = url {
      itemsToShare = [URL(string: safeUrl)!]
      let ac = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
      present(ac, animated: true)
    }
  }
  
  func createContentVC() -> ContentViewControllerProtocol {
    return ContentViewController(nibName: "ContentViewController", bundle: Bundle.main)
  }
  
  func hideNavigationBar() {
    self.navigationItem.title = ""
    self.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor:UIColor.black]
    
    self.navigationController?.navigationBar.tintColor = UIColor.black
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(),
                                                                for: .default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.isTranslucent = true
    
    UIApplication.shared.statusBarStyle = .default
    self.navigationItem.rightBarButtonItem = nil
  }
  
  func updateHeaderHeight() {
    guard let height = initialHeaderRect?.size.height else {
      return
    }
    if height + tableView.contentOffset.y >= height - topBarOffset {
      showNavigationBar()
    } else {
      hideNavigationBar()
    }
    
    var headerRect = CGRect(x: 0, y: -height, width: tableView.bounds.width, height: height)
    if tableView.contentOffset.y < -height {
      headerRect.origin.y = tableView.contentOffset.y
      headerRect.size.height = -tableView.contentOffset.y
    }
    
    if let headerView = tableHeaderView {
      headerView.frame = headerRect
    }
  }
  
  func showHeaderImage(imageUrl: String?) {
    
    guard let imageUrl = imageUrl else {
      tableHeaderView?.headerImage.image = Globals.Image.placeholder
      return
    }
    
    if imageUrl.contains(".gif") {
        do {
          let gifData = try Data(contentsOf: URL(string: imageUrl)!)
          tableHeaderView?.headerImage.image = UIImage.sd_animatedGIF(with: gifData)
        }
        catch {
          tableHeaderView?.headerImage.image = Globals.Image.placeholder
        }
    } else {
        tableHeaderView?.headerImage.sd_setImage(with: URL(string: imageUrl),
                                placeholderImage: Globals.Image.placeholder)
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
  
  func downloadContent(contentId: String) {
    self.hideNothingFoundView()
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    
    var reason: XMMContentReason = .unknown
    if (isBeacon) {
      reason = .notificationContentOpenRequest
    }
    
    ApiHelper.shared.downloadContent(withId: contentId, reason: reason, controller: self)
    { (content) in
      hud.hide(animated: true)
      
      if let content = content {
        self.showContent(content: content)
      } else {
        self.showNothingFoundView()
      }
    }
  }
  
  func downloadContent(with tag: String) {
    self.hideNothingFoundView()
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    ApiHelper.shared.downloadContents(withTag: tag, cursor: nil, completion: { (contents, cursor, hasMore) in
      hud.hide(animated: true)
      
      if contents.count > 0 {
        self.showContent(content: contents.first!)
        self.content = contents.first!
        if let id = self.content?.id {
          self.downloadContent(contentId: id as! String)
        }
      } else {
        self.showNothingFoundView()
      }
    })
  }
  
  func downloadContent(locId: String) {
    self.hideNothingFoundView()
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    
    ApiHelper.shared.downloadContent(withLocationIdentifier: locId, controller: self) { (content) in
      hud.hide(animated: true)
      
      if let content = content {
        self.showContent(content: content)
      } else {
        self.showNothingFoundView()
      }
    }
  }
  
  func showContent(content: XMMContent) {
    self.hideNothingFoundView()

    if let blocks = self.content?.contentBlocks as? [XMMContentBlock] {
      if blocks.count <= 1 {
        self.content = ContentHelper.addContentDescription(content: content);
      } else if let firstBlock = blocks[1] as? XMMContentBlock, firstBlock.blockType != 100 {
        self.content = ContentHelper.addContentDescription(content: content);
      }
    } else {
      self.content = ContentHelper.addContentDescription(content: content);
    }
    
    if let tags = content.tags as? [String], tags.contains(Globals.Tag.voucher) || tags.contains(Globals.Tag.voucher.uppercased()) {
        ApiHelper.shared.getVoucherStatus(withId: content.id as! String, completion: { status in
          if status {
            self.showRedeemVoucherButton()
          } else {
            self.showVoucherRedeemedButton()
          }
          if UserDefaults.standard.bool(forKey: Globals.Settings.isSocialSharingEnabled) {
              self.tableHeaderView?.addShareButton()
              self.tableHeaderView?.shareButton.addTarget(self, action: #selector(self.shareTapped), for: .touchUpInside)
          }
        })
    }
    
    if let title = content.title {
      AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Content screen \(title)")
    }
    self.contentBlocks?.display(self.content, addHeader: false)
    reloadContent = false
    showHeaderImage(imageUrl: content.imagePublicUrl)
  }
  
  
  private func showRedeemVoucherButton() {
    self.tableHeaderView?.releaseViewLabel.text = NSLocalizedString("voucher.redeem", comment: "")
    tableHeaderView?.releaseActionView.isHidden = false
    tableHeaderView?.releaseActionView.alpha = 1
    tableHeaderView?.releaseActionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.didClickScanQrNfcButton(sender:))))
  }
  
  private func showVoucherRedeemedButton() {
    self.tableHeaderView?.releaseViewLabel.text = NSLocalizedString("voucher.redeemed", comment: "")
    tableHeaderView?.releaseActionView.isHidden = false
    tableHeaderView?.releaseActionView.alpha = 0.7
    tableHeaderView?.releaseActionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.didClickRedeemedVoucherButton(sender:))))
  }
  
  private func handleScanResult(scannedText: String, type: ScanType, scanVC: ScanViewController) {
    ApiHelper.shared.redeemVoucher(withId: content!.id as! String, redeemCode: scannedText, completion: { (status, error) in
      if (error == nil) {
        self.showRedemptionNotification(title: String(format: NSLocalizedString("voucher.redemption.successful.notification", comment: ""), "\(self.content?.title ?? "")"))
        AnalyticsHelper.reportCustomEvent(name: "Voucher", action: "Voucher Redeemed",
                                          description: "Content id: \(self.content!.id)", code: nil)
        if status! {
          self.showRedeemVoucherButton()
        } else {
          self.showVoucherRedeemedButton()
        }
      } else {
          self.showRedemptionNotification(title: String(format: NSLocalizedString("voucher.redemption.error.notification", comment: ""), "\(self.content?.title ?? "")"))
      }
    })
  }
  
  private func showRedemptionNotification(title: String){
    let alert = UIAlertController(title: title,
                                  message: "",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(alert, animated: true)
  }
  
  @objc func didClickScanQrNfcButton(sender: Any) {
      let scanVC = ScanViewController(nibName: "ScanViewController", bundle: nil)
      scanVC.didScanAction = { (text, type) in
        self.handleScanResult(scannedText: text, type: type, scanVC: scanVC)
      }
      self.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(scanVC, animated: true)
      self.hidesBottomBarWhenPushed = false
  }
  
  @objc func didClickRedeemedVoucherButton(sender: Any) {
      let alert = UIAlertController(
        title: NSLocalizedString("voucher.redeemed.alert.title", comment: ""),
        message: NSLocalizedString("voucher.redeemed.alert.description", comment: ""),
        preferredStyle: .alert)
      
      let okAction = UIAlertAction(
        title: "OK",
        style: .default) { (action) in
          alert.dismiss(animated: true, completion: nil)
      }
      alert.addAction(okAction)
      
      self.present(alert, animated: true, completion: nil)
      
    }
  
  func didClickContentBlock(_ contentID: String!) {
    let controller = createContentVC()
    controller.contentId = contentID
    controller.hidesBottomBarWhenPushed = true
    navigationController?.pushViewController(controller, animated: true)
  }
  
  //This method is implemented in Quiz apps only
  func onQuizHTMLResponse(_ htmlResponse: String!) {
  }
}

extension ContentViewController : UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    contentBlocks?.tableView(tableView, didSelectRowAt: indexPath)
  }
}

extension ContentViewController : UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateHeaderHeight()
  }
}

extension ContentViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
