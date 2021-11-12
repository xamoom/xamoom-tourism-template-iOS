//
//  QuizScoreViewController.swift
//  tourismtemplate
//
//  Created by G0yter on 07.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import MBProgressHUD

enum ScoreDisplayType {
    case title
    case text
    case quizField
    case quizPage
}

class QuizScoreViewController: UIViewController {

    
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var scores: [QuizScore] = []
    
    var initialHeaderRect: CGRect?
    var headerView: UIView?
    var topBarOffset: CGFloat!
    var tableHeaderView: ContentTableHeaderView?
    @available(iOS 13.0, *)
    lazy var apppearanceCopy = UINavigationBar.appearance().standardAppearance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Quiz Score screen")
        
        
        appendDataToTableView()
        initTableView()
        
        hideNavigationBar()
        topBarOffset = UIApplication.shared.statusBarFrame.size.height + (navigationController?.navigationBar.frame.size.height)!
        setupHeaderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        setupContentOffset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateHeaderHeight()
        tableHeaderView?.headerImage.image = UIImage(named: "header-score")
    }
    
    
    private func appendDataToTableView() {
        let infoQuiz: (title: String, subtitle: String) = (title: NSLocalizedString("quiz.score.info.title", comment: ""), subtitle: NSLocalizedString("quiz.score.info.subtitle", comment: ""))
        scores = [QuizScore(type: .title, value: NSLocalizedString("quiz.score.title", comment: "")),
                          QuizScore(type: .text, value: NSLocalizedString("quiz.score.subtitle", comment: "")),
                          QuizScore(type: .quizField, value: "\(QuizHelper.getPointsAmount()) \(NSLocalizedString("quiz.score.points", comment: ""))"),
                          QuizScore(type: .text, value: NSLocalizedString("quiz.score.points.subtitle", comment: "")),
                          QuizScore(type: .quizField, value: "\(NSLocalizedString("quiz.score.level", comment: "")) \(QuizHelper.getCurrentLevel())"),
                          QuizScore(type: .quizPage, value: infoQuiz)
                ]
    }
    
    func initTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.rowHeight = UITableViewAutomaticDimension
      
        tableView.register(UINib(nibName: "ImageSliderTableViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: ImageSliderTableViewCell.identifier)
        tableView.register(UINib(nibName: "TextCell", bundle: Bundle.main),
                           forCellReuseIdentifier: TextCell.identifier)
        tableView.register(UINib(nibName: "QuizLinkTableViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: QuizLinkTableViewCell.identifier)
        tableView.register(UINib(nibName: "CenteredTextCell", bundle: Bundle.main),
                           forCellReuseIdentifier: CenteredTextCell.identifier)
    }
    
    //MARK: - Customize Navigation bar
    
    override func viewDidLayoutSubviews() {
        updateHeaderHeight()
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
    
    func showNavigationBar() {
      self.navigationController?.navigationBar.titleTextAttributes =
        [NSAttributedStringKey.foregroundColor:Globals.Color.tabbarSelected]
      
      self.navigationController?.navigationBar.tintColor = Globals.Color.tabbarSelected
      self.navigationController?.navigationBar.setBackgroundImage(nil,
                                                                  for: .default)
      self.navigationController?.navigationBar.shadowImage = nil
      self.navigationController?.navigationBar.isTranslucent = true
      UIApplication.shared.statusBarStyle = Globals.Color.barFontColor.isDark ? .default : .lightContent
    }
    
    func hideNavigationBar() {
      self.navigationController?.navigationBar.titleTextAttributes =
        [NSAttributedStringKey.foregroundColor:UIColor.black]
      
      self.navigationController?.navigationBar.tintColor = UIColor.black
      self.navigationController?.navigationBar.setBackgroundImage(UIImage(),
                                                                  for: .default)
      self.navigationController?.navigationBar.shadowImage = UIImage()
      self.navigationController?.navigationBar.isTranslucent = true
      
      UIApplication.shared.statusBarStyle = .default
    }
    
    func setupHeaderView() {
      
      initialHeaderRect = headerImage.frame
      tableView.tableHeaderView = nil

      let tableHeaderView : ContentTableHeaderView = UIView.fromNib()
      
      tableHeaderView.releaseActionView.layer.cornerRadius = 4.0
      tableHeaderView.releaseActionView.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
      
      tableView.addSubview(tableHeaderView)
      self.tableHeaderView = tableHeaderView
    }
    
    func setupContentOffset() {
      if let height = initialHeaderRect?.size.height {
        tableView.contentInset = UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -height)
      }
    }
}

extension QuizScoreViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return scores.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        let type = scores[indexPath.row].type as ScoreDisplayType
        
        switch type {
        case .title:
            let titleCell = tableView.dequeueReusableCell(withIdentifier:
              TextCell.identifier) as! TextCell
            titleCell.configureCell(forType: type)
            titleCell.cellTextLabel.text = scores[indexPath.row].value as! String
            cell = titleCell
        case .text:
            let textCell = tableView.dequeueReusableCell(withIdentifier:
              TextCell.identifier) as! TextCell
            textCell.configureCell(forType: type)
            textCell.cellTextLabel.text = scores[indexPath.row].value as! String
            cell = textCell
        case .quizField:
            let resultCell = tableView.dequeueReusableCell(withIdentifier:
                                                            CenteredTextCell.identifier) as! CenteredTextCell
            resultCell.cellTextLabel.text = scores[indexPath.row].value as! String
            resultCell.cellTextLabel.font = UIFont.systemFont(ofSize: 24)
            resultCell.cellTextLabel.textColor = Globals.Color.textColor
            resultCell.cellContainer.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
            cell = resultCell
        case .quizPage:
            let quizPageCell = tableView.dequeueReusableCell(withIdentifier:
              QuizLinkTableViewCell.identifier) as! QuizLinkTableViewCell
            quizPageCell.configureCell()
            let textValues = scores[indexPath.row].value as! (title: String, subtitle: String)
            quizPageCell.titleLabel.text = textValues.title
            quizPageCell.subtitleLabel.text = textValues.subtitle
            cell = quizPageCell
        }
        cell?.selectionStyle = .none
        
        return cell!
    }
}

extension QuizScoreViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderHeight()
    }
}

extension QuizScoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if scores[indexPath.row].type == .quizPage {
            let quizPageVC = QuizPageScreenViewController(nibName: "QuizPageScreenViewController", bundle: Bundle.main)
            navigationController?.pushViewController(quizPageVC, animated: true)
        }
    }
}
