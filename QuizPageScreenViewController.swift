//
//  QuizPageScreenViewController.swift
//  tourismtemplate
//
//  Created by G0yter on 07.05.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import MBProgressHUD


class QuizPageScreenViewController: UIViewController {
    
    enum QuizPassStatus: Int {
        case notPassed = 0
        case passed = 1
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    
    private var overlayView: UIView?
    
    private var segmentedControl: UISegmentedControl?
    private var loadedContent: [XMMContent] = []
    private var contents: [XMMContent] = []
    private var selectedIndex = 0
    private var apppearanceStandartCopy: Any?
    private var apppearanceScrollCopy: Any?
    private var capppearanceStandartCopy: Any?
    private var capppearanceScrollCopy: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Quizzes screen")
        
        loadContent(cursor: nil)
        initTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        setupNavigationBar()
                
        if self.navigationController != nil {
           showNavigationBar()
        }
        self.updateContent()

    }
    
    func loadContent(cursor: String?) {
        let loadingHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        ApiHelper.shared.downloadContents(withTag: Globals.Tag.quiz, cursor: cursor, desc: false) { (contents, cursor, hasMore) in
                loadingHud.hide(animated: true)
                self.loadedContent.append(contentsOf: contents)
                self.updateContent()
            
            if (hasMore) {
                self.loadContent(cursor: cursor)
            }
        }
    }
    
    func initTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
      
        tableView.register(UINib(nibName: "ContentLinkTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: ContentLinkTableViewCell.identifier)
        tableView.register(UINib(nibName: "SubtitleTableViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: SubtitleTableViewCell.identifier)
    }
    
    func updateContent() {
        switch selectedIndex {
        case QuizPassStatus.passed.rawValue:
            self.setupPassedPage()
        case QuizPassStatus.notPassed.rawValue:
            self.setupNotPassedPage()
        default:
            break
        }
        tableView.reloadData()
    }
    
    func setupSegmentedControl() {
        segmentedControl = UISegmentedControl(items: [
            NSLocalizedString("quiz.screen.switcher.second", comment: ""),
            NSLocalizedString("quiz.screen.switcher.first", comment: "")
          ])
        segmentedControl?.tintColor = UIColor.clear
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        segmentedControl?.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: Globals.Color.textColor]
        segmentedControl?.setTitleTextAttributes(normalTextAttributes, for: .normal)
        
        if #available(iOS 13.0, *) {
            segmentedControl?.selectedSegmentTintColor = Globals.Color.textColor
        } else {
            segmentedControl?.tintColor = Globals.Color.textColor
        }
        
        
        segmentedControl!.addTarget(self,
                                   action: #selector(selectSegmentedControl(_:)),
                                   for: .valueChanged)
        segmentedControl!.selectedSegmentIndex = selectedIndex
    }
    
    @objc func selectSegmentedControl(_ sender: UISegmentedControl) {
        selectedIndex = sender.selectedSegmentIndex
        switch selectedIndex {
        case QuizPassStatus.passed.rawValue:
            self.updateContent()
        case QuizPassStatus.notPassed.rawValue:
            self.updateContent()
        default:
            break
        }
    }
    
    func setupPassedPage() {
        self.contents = QuizHelper.filterQuizzes(quizzes: self.loadedContent, isPassed: true)
        addHeaderDescriptionCell()
    }
    
    func setupNotPassedPage() {
        self.contents = QuizHelper.filterQuizzes(quizzes: self.loadedContent, isPassed: false)
        addHeaderDescriptionCell()
    }
    
    func addHeaderDescriptionCell() {
        let contentHeader = XMMContent()
        if (selectedIndex == 0) {
            contentHeader.title = NSLocalizedString("quiz.screen.open.title", comment: "")
            contentHeader.contentDescription = NSLocalizedString("quiz.screen.open.description", comment: "")
        } else if (selectedIndex == 1) {
            contentHeader.title = NSLocalizedString("quiz.screen.solved.title", comment: "")
            contentHeader.contentDescription = NSLocalizedString("quiz.screen.solved.description", comment: "")
        }
        
        self.contents.insert(contentHeader, at: 0)
    }
    
    func removeBlurView() {
        overlayView?.removeFromSuperview()
    }

    func setupNavigationBar() {
        setupSegmentedControl()
        self.navigationItem.titleView = segmentedControl
        
        self.navigationController!.navigationBar.titleTextAttributes =
          [NSAttributedStringKey.foregroundColor:Globals.Color.tabbarSelected]
        self.navigationController?.navigationBar.tintColor = Globals.Color.tabbarSelected
        self.navigationController?.navigationBar.setBackgroundImage(nil,
                                                                    for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        
        UIApplication.shared.statusBarStyle = Globals.Color.barFontColor.isDark ? .default : .lightContent
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            if Globals.isBackgroundImage.elementsEqual("true") {
                navigationController?.navigationBar.setBackgroundImage(UIImage(named: "background_image"), for: .default)
            }
        }
        
        if #available(iOS 11.0, *) {
          view.addConstraint(NSLayoutConstraint(item: tableView,
                                                                attribute: .top,
                                                                relatedBy: .equal,
                                                                toItem: view.safeAreaLayoutGuide,
                                                                attribute: .top,
                                                                multiplier: 1.0,
                                                                constant: 0))
        } else {
            let navBarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
          view.addConstraint(NSLayoutConstraint(item: tableView,
                                                              attribute: .top,
                                                              relatedBy: .equal,
                                                              toItem: view,
                                                              attribute: .top,
                                                              multiplier: 1.0,
                                                              constant: navBarHeight + 20))
        }
    }
    
    private func showNavigationBar() {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 15.0, *) {
            let appearanceStandart = UINavigationBarAppearance()
            appearanceStandart.configureWithOpaqueBackground()
            appearanceStandart.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
            appearanceStandart.shadowColor = .clear
            let appearanceScroll = UINavigationBarAppearance()
            appearanceScroll.configureWithOpaqueBackground()
            appearanceScroll.backgroundColor = nil
            appearanceScroll.shadowColor = .clear
            self.navigationController?.navigationBar.standardAppearance = appearanceStandart
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearanceScroll
        }
    }
}

extension QuizPageScreenViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let quizVC = QuizContentViewController(nibName: "QuizContentViewController", bundle: Bundle.main)
        quizVC.content = contents[indexPath.row]
        self.navigationController?.pushViewController(quizVC, animated: true)
    }
}

extension QuizPageScreenViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        
        if indexPath.row == 0 {
            let subtitleCell = tableView.dequeueReusableCell(withIdentifier:
                                                        SubtitleTableViewCell.identifier) as! SubtitleTableViewCell
            subtitleCell.titleLabel.text = contents[indexPath.row].title
            subtitleCell.subtitleLabel.text = contents[indexPath.row].contentDescription
            cell = subtitleCell
        } else {
            let linkedCell = tableView.dequeueReusableCell(withIdentifier:
                                                        ContentLinkTableViewCell.identifier) as! ContentLinkTableViewCell
            linkedCell.configureCell(content: contents[indexPath.row])
            cell = linkedCell
        }
        
        return cell!
    }
}
