//
//  OnbardViewController.swift
//  tourismtemplate
//
//  Created by Petar Cekic on 05.02.20.
//  Copyright © 2020 xamoom GmbH. All rights reserved.
//

import UIKit
import SDWebImage
import XamoomSDK
import RMPickerViewController

class OnboardViewController: UIViewController {

  @IBOutlet weak var onboardImageView: UIImageView!
  @IBOutlet weak var titleTextView: UITextView!
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var actionButtonView: UIView!
  @IBOutlet weak var skipButtonView: UIView!
  @IBOutlet weak var actionButtonLabel: UILabel!
  @IBOutlet weak var skipButtonLabel: UILabel!
  @IBOutlet weak var pageControlView: UIPageControl!
  @IBOutlet weak var skipImageView: UIImageView!
    
  var contentList: [XMMContent]?
  var inAppNotificationHelper: InAppNotificationHelper?
  var currentScreenIndex = 0
  var nextControllerToLoad: UIViewController?
  var dots:[UIImageView] = [UIImageView]()
  let lang = ApiHelper.shared.deviceLanguage()
  let descriptionLengthLimit = 230
    
  override func viewDidLoad() {
    super.viewDidLoad()
  
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Onboarding screen")
    UIApplication.shared.statusBarStyle = .lightContent
    navigationController?.navigationBar.tintColor = UIColor.white
    if Globals.isBackgroundImage.elementsEqual("true") {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background_image")!)
    } else {
        view.backgroundColor = Globals.Color.primaryColor
    }
    actionButtonLabel.textColor = Globals.Color.primaryColor
    if hexStringFromColor(color: Globals.Color.textColor).elementsEqual("#000000") {
        skipImageView.image = UIImage(named: "right-arrow-black")
    } else {
        skipImageView.image = UIImage(named: "right-arrow-white")
    }
        
    
    descriptionTextView.textContainerInset = .zero
    descriptionTextView.textContainer.lineFragmentPadding = 0
    titleTextView.textColor = Globals.Color.textColor
    descriptionTextView.textColor = Globals.Color.textColor
    titleTextView.textContainerInset = .zero
    titleTextView.textContainer.lineFragmentPadding = 0

    actionButtonView.layer.cornerRadius = 6.0
    actionButtonView.backgroundColor = Globals.Color.textColor
    
    pageControlView.pageIndicatorTintColor = Globals.Color.textColor.withAlphaComponent(0.5)
    pageControlView.currentPageIndicatorTintColor = Globals.Color.textColor
    skipButtonLabel.textColor = Globals.Color.textColor
    
    inAppNotificationHelper = InAppNotificationHelper()
    inAppNotificationHelper?.view = UIApplication.shared.windows.first
    
    actionButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.didClickActionButton(sender:))))
    skipButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.didClickSkipButton(sender:))))

    downloadContent(with: Globals.Tag.onboarding)
  }
    
  private func hexStringFromColor(color: UIColor) -> String {
       let components = color.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       var b: CGFloat? = 0
       if (components?.count ?? 0) > 2 {
        b = components?[2] ?? 0.0
       }
       

    let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b!  * 255)))
       print(hexString)
       return hexString
  }
  
  func downloadContent(with tag: String) {
     ApiHelper.shared.downloadContents(withTag: tag, cursor: nil, completion: { (contents, cursor, hasMore) in
       if contents.count > 0 {
        self.contentList = contents
        self.showScreenAtPosition(position: 0)
        self.initDots(dotsCount: contents.count)
       } else {
        self.finishOnboarding()
       }
     })
   }
    
  func showScreenAtPosition(position: Int) {
    if let contents = contentList {
      if position > contents.count - 1 { return }
      let content = contents[position]
      pageControlView.currentPage = position
      
      if position == contents.count - 1 {
        skipButtonView.isHidden = true
        // disable skip button
      }
      
      if position == 0 {
        skipButtonLabel.text = content.customMeta["skip-label-" + lang] as? String ?? NSLocalizedString("onboard.skip", comment: "")
      }
      
      titleTextView.text = content.title
      
      descriptionTextView.text = content.contentDescription.count < descriptionLengthLimit ? content.contentDescription : content.contentDescription.prefix(descriptionLengthLimit) + "..."
      actionButtonLabel.text = getCurrentActionButtonText(position: position)
      
      if let imageUrl = content.imagePublicUrl {
        onboardImageView.sd_setImage(with: URL(string: imageUrl),
        placeholderImage: Globals.Image.placeholder)
      }
      
    }
  }
  
  func getCurrentActionButtonText(position: Int) -> String {
    if let contents = contentList {
      if (contents[position].customMeta["permission-location"] != nil ||
        contents[position].customMeta["permission-notification"] != nil) {
        return contents[position].customMeta["allow-label-" + lang] as? String ??
          NSLocalizedString("onboard.action.allow", comment: "")
      }
      if (position == contents.count - 1) {
        return contents[position].customMeta["end-label-" + lang] as? String ?? NSLocalizedString("onboard.action.more", comment: "")
      }
      
      return contents[position].customMeta["more-label-" + lang] as? String ?? NSLocalizedString("onboard.action.more", comment: "")
    }
    return ""
  }
  
  @objc func didClickSkipButton(sender: UITapGestureRecognizer) {
    skipOnboarding()
  }
  
  @objc func didClickActionButton(sender: UITapGestureRecognizer) {
  
    if let contents = contentList {

      if contents[currentScreenIndex].customMeta["permission-location"] != nil {
        //request Permission
        ApiHelper.shared.initLocationHelperWithBeacon()
      }
      if contents[currentScreenIndex].customMeta["permission-notification"] != nil {

        PushNotificationHelper.requestNotificationAuthorization {
          DispatchQueue.main.async {
            self.finishdidClickActionButton(contentsCount: contents.count)
            }
        }
        return
      }
        finishdidClickActionButton(contentsCount: contents.count)
    }
  }
  
    func finishdidClickActionButton(contentsCount: Int) {
        if currentScreenIndex == contentsCount - 1 {
          finishOnboarding()
          return
        }
        currentScreenIndex+=1
        showScreenAtPosition(position: currentScreenIndex)
    }
    
  func skipOnboarding() {
    if let contents = contentList {
      currentScreenIndex = contents.count - 1
      showScreenAtPosition(position: currentScreenIndex)
    }
  }
  
  func finishOnboarding() {
    UserDefaults.standard.set(true, forKey: Globals.Settings.onboardingPassedKey)
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    appdelegate.window!.rootViewController = nextControllerToLoad
  }
  
  func initDots(dotsCount: Int) {
    pageControlView.numberOfPages = dotsCount
    pageControlView.subviews.forEach {
      $0.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
    }
    pageControlView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
  }
  
}
