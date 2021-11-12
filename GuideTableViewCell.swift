//
//  GuideTableViewCell.swift
//  tourismtemplate
//
//  Created by G0yter on 11.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit

enum GuideCellDisplayType {
    case quizScore
    case quizPageScreen
}

class GuideTableViewCell: UITableViewCell {
    public static let identifier = "GuideTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate : GuideInteractionProtocol?
    var title: String? {
      didSet {
        self.titleLabel.text = title
      }
    }
    
    var quizScoreItem = GuideItem.init(title: "Punktestand", image: Globals.isBackgroundImage == "true" ? UIImage(named: "background_score") : nil, displayType: .quizScore)
    var quizPageScreenItem = GuideItem.init(title: "Rätselübersicht", image: Globals.isBackgroundImage == "true" ? UIImage(named: "background_overview") : nil, displayType: .quizPageScreen)
    
    var items: [GuideItem] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initCollectionView()
    }
    
    func initCollectionView() {
        collectionView.register(
            UINib(nibName: "GuideCollectionViewCell", bundle: Bundle.main),
            forCellWithReuseIdentifier: GuideCollectionViewCell.identifier)
      
        items = [quizScoreItem, quizPageScreenItem]
        print(Globals.Features.quiz)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension GuideTableViewCell: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    self.delegate?.didClick(itemPosition: indexPath.row, cellIdentifier: items[indexPath.row].displayType)
  }
}

extension GuideTableViewCell: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count;
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    var cell: GuideCollectionViewCell!
    cell = collectionView.dequeueReusableCell(withReuseIdentifier: GuideCollectionViewCell.identifier, for: indexPath) as! GuideCollectionViewCell
    cell.configureCell(item: items[indexPath.row])
    return cell;
  }
}

extension GuideTableViewCell: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return Globals.Size.contentCollectionViewCellSize
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return Globals.Size.contentCollectionViewInsets
  }
}
