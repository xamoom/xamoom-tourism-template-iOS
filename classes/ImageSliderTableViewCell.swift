//
//  ImageSliderTableViewCell.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 19/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import ImageSlideshow
import XamoomSDK

class ImageSliderTableViewCell: UITableViewCell {
  public static let identifier = "ImageSliderTableViewCell"
  
  @IBOutlet weak var imageSlider: ImageSlideshow!
  @IBOutlet weak var sliderLabel: UILabel!

  var delegate : ContentInteractionProtocol?
  var contents: [XMMContent] = []
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    sliderLabel.text = ""
    imageSlider.contentScaleMode = .scaleAspectFill
    imageSlider.slideshowInterval = 7
    imageSlider.pageControlCenterPositionBottomOffset = 28
    let tapRecognizer = UITapGestureRecognizer(target: self,
                                               action: #selector(didClickSlider(recognizer:)))
    imageSlider.addGestureRecognizer(tapRecognizer)
    imageSlider.currentPageChanged = { page in
      self.updateSliderLabel(for: page)
    }
  }
  
  func updateCell() {
    self.contents.removeAll()
    downloadTopTips()
  }
  
  func downloadTopTips() {
    ApiHelper.shared.downloadContents(
      withTag: Globals.Tag.topTip,
      cursor: nil) { (contents, cursor, hasMore) in
        self.contents = contents
        self.updateSlider(contents: self.contents)
        self.updateSliderLabel(for: 0)
        self.imageSlider.setCurrentPage(0, animated: true)
    }
  }
  
  func updateSlider(contents: [XMMContent]) {
    var sources: [InputSource] = []
    for content in contents {
      if let contentImageUrl = content.imagePublicUrl {
        sources.append(SDWebImageSource(urlString: contentImageUrl)!)
      } else {
        sources.append(ImageSource(image: UIImage(named: "placeholder")!))
      }
    }
    imageSlider.setImageInputs(sources)
  }
  
  func updateSliderLabel(for page: Int) {
    if page > (contents.count - 1) {
      return
    }
    
    let content = contents[page]
    sliderLabel.text = content.title
  }
  
  @objc func didClickSlider(recognizer: UIGestureRecognizer) {
    if let content = contents[safe: imageSlider.currentPage] {
        delegate?.didClick(content: content, isBeacon: false)
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
