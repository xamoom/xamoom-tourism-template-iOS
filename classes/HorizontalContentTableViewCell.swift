//
//  HorizontalContentTableViewCell.swift
//  app-generator
//
//  Created by Thomas Krainz-Mischitz 2019.
//  Copyright © 2019 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import CoreLocation

class HorizontalContentTableViewCell: UITableViewCell {
  public static let identifier = "HorizontalContentTableViewCell"
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var collectionView: UICollectionView!
  
  var type: DisplayType = .Horizontal
  
  var delegate : ContentInteractionProtocol?
  var title: String? {
    didSet {
      self.titleLabel.text = title
    }
  }
  var contentTag: String? {
    didSet {
      downloadContents(isLoadMore: false)
    }
  }
  var beaconContents: [XMMContent] = [] {
    didSet {
      hasMore = false
      self.contents = beaconContents
      self.collectionView.reloadData()
    }
  }
  
  var contents: [XMMContent?] = []
  var loadingBeacons: [CLBeacon] = []
  
  var cursor: String? = nil
  var hasMore = true
  var loading = false
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    
    initCollectionView()
  }
  
  override func prepareForReuse() {
    contentTag = nil
    contents = []
    beaconContents = []
    collectionView.reloadData()
    hasMore = true
    cursor = nil
  }
  
  func initCollectionView() {
    collectionView.dataSource = self
    collectionView.delegate = self
    
    collectionView.register(
      UINib(nibName: "ContentCollectionViewCell", bundle: Bundle.main),
      forCellWithReuseIdentifier: ContentCollectionViewCell.identifier)
    collectionView.register(
      UINib(nibName: "LoadingCollectionViewCell", bundle: Bundle.main),
      forCellWithReuseIdentifier: LoadingCollectionViewCell.identifier)
  }
  
    func downloadContents(isLoadMore: Bool) {
    if hasMore == false {
      return
    }
    
    addLoadingCell()
    
    if let contentTag = contentTag, type != .Nearby {
      loading = true
      ApiHelper.shared.downloadContents(withTag: contentTag, cursor: cursor) { (contents, cursor, hasMore) in
        
        self.loading = false
        self.cursor = cursor
        self.hasMore = hasMore
        self.removeLoadingCell()
        
        if contents.count == 0 {
          self.titleLabel.isHidden = true
          self.contents = []
          self.delegate?.removeEmptyCell(tag: contentTag)
        } else {
          self.titleLabel.isHidden = false
          if (!isLoadMore) {
            self.contents.removeAll()
          }
          self.contents.append(contentsOf: contents as [XMMContent?])
        }
        
        self.collectionView.reloadData()
      }
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func addLoadingCell() {
    //if contents.count > 0 {
    
    let lastContent: XMMContent? = contents.last ?? nil
    if lastContent != nil || contents.count == 0 {
      contents.append(nil)
      collectionView.reloadData()
    }
    //}
  }
  
  func removeLoadingCell() {
    if contents.count > 0 {
      let lastContent: XMMContent? = contents.last!
      if lastContent == nil {
        contents.removeLast()
        collectionView.reloadData()
      }
    }
  }
}

extension HorizontalContentTableViewCell: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let cellContent = contents[indexPath.row] {
        delegate?.didClick(content: cellContent, isBeacon: false)
    }
  }
}

extension HorizontalContentTableViewCell: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if type == .Nearby {
      return beaconContents.count
    }
    
    return contents.count;
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    var cont = contents
    if type == .Nearby {
      cont = beaconContents
    }
    
    let content = cont[indexPath.row]
    var cell: UICollectionViewCell!
    
    if indexPath.row == self.contents.count - 1 {
      if hasMore && !loading {
        downloadContents(isLoadMore: true)
      }
    }
    
    if content != nil {
      let contentCell = collectionView.dequeueReusableCell(
        withReuseIdentifier: ContentCollectionViewCell.identifier,
        for: indexPath) as! ContentCollectionViewCell
      contentCell.configureCell(content: content!)
      cell = contentCell
    } else {
      let loadingCell = collectionView.dequeueReusableCell(
        withReuseIdentifier: LoadingCollectionViewCell.identifier,
        for: indexPath) as! LoadingCollectionViewCell
      loadingCell.setup()
      cell = loadingCell
    }
    
    return cell;
  }
}

extension HorizontalContentTableViewCell: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let content = contents[safe: indexPath.row]
    
    if (content == nil) {
      return CGSize(width: 50.0, height: Globals.Size.contentCollectionViewCellSize.height)
    }
    
    return Globals.Size.contentCollectionViewCellSize
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return Globals.Size.contentCollectionViewInsets
  }
}
