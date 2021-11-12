//
//  MapDetailView.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 25/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

protocol MapDetailViewDelegate {
  func openContent(content: XMMContent)
}

class MapDetailView: UIView {
  @IBOutlet weak var navigationButton: UIButton!
  @IBOutlet weak var moreButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var descriptionText: UILabel!
  @IBOutlet weak var visualEffectView: UIVisualEffectView!
  
  var delegate: MapDetailViewDelegate?
  var spot: XMMSpot? {
    didSet {
      updatViewContent()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    loadViewFromNib()
    setupTexts()
    setupColors()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func awakeFromNib() {
    // texts
  }
  
  override func layoutSubviews() {
    descriptionText.sizeToFit()
  }
  
  func loadViewFromNib() {
    let views = Bundle.main.loadNibNamed("MapDetailView", owner: self, options: nil)
    let view = views?.first as! UIView
    addSubview(view)
    
    view.frame = self.bounds
  }
  
  func setupTexts() {
    navigationButton.setTitle(NSLocalizedString("mapDetailView.navigation", comment: "")
, for: .normal)
    moreButton.setTitle(NSLocalizedString("mapDetailView.textButtonLabel", comment: ""), for: .normal)
  }
    
  func setupColors() {
    moreButton.backgroundColor = Globals.Color.primaryColor
    moreButton.setTitleColor(Globals.Color.barFontColor, for: .normal)
    
    navigationButton.backgroundColor = Globals.Color.primaryColor
    navigationButton.setTitleColor(Globals.Color.barFontColor, for: .normal)
      
    if #available(iOS 13.0, *), UITraitCollection.current.userInterfaceStyle == .dark {
      visualEffectView.effect = UIBlurEffect(style: .dark)
    } else {
      visualEffectView.effect = UIBlurEffect(style: .light)
    }
  }
  
  func updatViewContent() {
    guard let spot = spot else {
      return
    }
    
    titleLabel.text = spot.name
    descriptionText.text = spot.spotDescription
    if let imageUrl = spot.image {
      imageView.sd_setImage(with: URL(string: imageUrl),
                            placeholderImage: Globals.Image.placeholder)
    } else {
      imageView.image = Globals.Image.placeholder
    }
    
    moreButton.isHidden = spot.content == nil
  }
  
  @IBAction func didTapNavigationButton(_ sender: Any) {
    guard let spot = spot else {
      return
    }
    
    var directionMode = MKLaunchOptionsDirectionsModeDriving
    
    switch (UserDefaults.standard.integer(forKey: Globals.Settings.navigationKey)) {
    case 0: directionMode = MKLaunchOptionsDirectionsModeWalking
      break
    case 1: directionMode = MKLaunchOptionsDirectionsModeDriving
      break
    case 2: directionMode = MKLaunchOptionsDirectionsModeTransit
      break
    default: break
    }
    
    let options = [MKLaunchOptionsDirectionsModeKey: directionMode]
    let coordinates = CLLocationCoordinate2D(latitude: spot.latitude,
                                             longitude: spot.longitude)
    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = spot.name
    mapItem.openInMaps(launchOptions: options)
  }
  
  @IBAction func didTapMoreButton(_ sender: Any) {
    if let content = spot?.content {
      delegate?.openContent(content: content)
    }
  }
  
}

