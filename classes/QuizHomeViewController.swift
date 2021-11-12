//
//  QuizHomeViewController.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit
import ImageSlideshow
import XamoomSDK
import MBProgressHUD

class QuizHomeViewController: HomeViewController {
    

    override func initTableView() {
      tableView.delegate = self
      tableView.dataSource = self
      tableView.separatorStyle = .none
      tableView.estimatedRowHeight = 200
      tableView.rowHeight = UITableViewAutomaticDimension
      
      tableView.register(UINib(nibName: "HorizontalContentTableViewCell", bundle: Bundle.main),
                         forCellReuseIdentifier: HorizontalContentTableViewCell.identifier)
      tableView.register(UINib(nibName: "ImageSliderTableViewCell", bundle: Bundle.main),
                         forCellReuseIdentifier: ImageSliderTableViewCell.identifier)
      tableView.register(UINib(nibName: "GuideTableViewCell", bundle: Bundle.main),
                         forCellReuseIdentifier: GuideTableViewCell.identifier)
    }
    
    override func initizializeStartGrid() {
      elementTags = [nil]
      elementTypes = [DisplayType.Slider]
      tableView.reloadData()
      
      self.hideNothingFoundView()
      let loadingHud = MBProgressHUD.showAdded(to: self.view, animated: true)
      
      ApiHelper.shared.downloadContents(withTag: Globals.Tag.config, cursor: nil, desc: false) { (contents, cursor, hasMore) in
        loadingHud.hide(animated: true)
        
        if let content = contents.first, let customMeta = content.customMeta {
          self.tableView.isHidden = false
          self.hideNothingFoundView()
            
          self.addGuide()
          
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
          if (self.isNeedToSendGeaogenseRequest) {
            self.downloadGeofenceRegions()
            self.isNeedToSendGeaogenseRequest = false
        }
      }
    }
    
    func addGuide() {
      var indexPath: IndexPath = IndexPath(row: 1, section: 0)
      if !elementTypes.contains(.Guide) {
        elementTypes.insert(.Guide, at: indexPath.row)
        elementTags.insert(nil, at: indexPath.row)
        self.tableView.insertRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .fade)
      }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
      } else if type == .Guide {
          let guideCell = tableView.dequeueReusableCell(withIdentifier:
            GuideTableViewCell.identifier) as! GuideTableViewCell
          guideCell.title = NSLocalizedString("home.quiz.block.title",
                                              comment: "Quizzes")
          guideCell.delegate = self
          cell = guideCell
      } else {
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
    
    override func addNearby() {
      let indexPath = IndexPath(row: 2, section: 0)
      
      if elementTypes.count > 2 && elementTypes[2] == .Nearby {
        if nearbyContentSizeChanged {
          tableView.reloadRows(at: [indexPath], with: .none)
        }
        return
      }
      
      if elementTypes.count > 1 && !elementTypes.contains(.Nearby) {
        elementTypes.insert(.Nearby, at: 2)
        elementTags.insert(nil, at: 2)
        self.tableView.reloadData()
      }
    }
    
    override func removeNearby() {
      if elementTypes.count > 2 {
        if elementTypes[2] != .Nearby {
          return
        }
        
        elementTypes.remove(at: 2)
        elementTags.remove(at: 2)
        self.tableView.reloadData()
      }
    }
    
    override func didClick(content: XMMContent, isBeacon: Bool) {
      let controller = QuizContentViewController(nibName: "QuizContentViewController", bundle: Bundle.main)
      controller.isBeacon = isBeacon
      controller.content = content
      controller.hidesBottomBarWhenPushed = true
      navigationController?.pushViewController(controller, animated: true)
    }
}

extension HomeViewController: GuideInteractionProtocol {
    func didClick(itemPosition: Int, cellIdentifier: GuideCellDisplayType) {
        
        switch cellIdentifier {
        case GuideCellDisplayType.quizScore:
            let quizScoreVC = QuizScoreViewController(nibName: "QuizScoreViewController", bundle: Bundle.main)
            quizScoreVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(quizScoreVC, animated: true)
        case GuideCellDisplayType.quizPageScreen:
            let quizPageScreenVC = QuizPageScreenViewController(nibName: "QuizPageScreenViewController", bundle: Bundle.main)
            quizPageScreenVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(quizPageScreenVC, animated: true)
        }
    }
}
