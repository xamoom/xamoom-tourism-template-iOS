//
//  FilterViewController.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 26/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

protocol FilterViewControllerDelegate {
  func didUpdateFilter(filters: [String])
}

class FilterViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var selectAllLabel: UILabel!
  @IBOutlet weak var selectAllSwitch: UISwitch!
  
  var tags: [String: Dictionary<String, String>] = Globals.MapFilter.tags
  var delegate: FilterViewControllerDelegate?
  var maxFilterSize: Int?
  var startFilters: [String] = []
  var filters: [String] = [] {
    didSet {
      if maxFilterSize == nil {
        maxFilterSize = FilterHelper.getAllFilterNames().count
        startFilters = filters
      }
      updateAllSwitch()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Filter screen")
    AnalyticsHelper.reportContentView(contentName: "Filter",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: "",
                                      customAttributes: nil)
    
    UIApplication.shared.statusBarStyle = .lightContent
    navigationController?.navigationBar.tintColor = UIColor.white
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
    navigationItem.title = NSLocalizedString("filterViewController.title", comment: "")
    
    let doneButton = UIBarButtonItem(title: NSLocalizedString("filterViewController.done", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(doneButton(recognizer:)))
    navigationItem.rightBarButtonItem = doneButton
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: "FilterTableViewCell", bundle: Bundle.main),
                       forCellReuseIdentifier: FilterTableViewCell.identifier)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    updateAllSwitch()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    if containSameElements(startFilters, filters) == false {
      delegate?.didUpdateFilter(filters: filters)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @objc func doneButton(recognizer: UIGestureRecognizer) {
    dismiss(animated: true, completion: nil)
  }
  
  func updateAllSwitch() {
    guard let selectAllSwitch = selectAllSwitch else {
      return
    }
    
    if filters.count == maxFilterSize {
      selectAllSwitch.isOn = true
    } else {
      selectAllSwitch.isOn = false
    }
  }
  
  @IBAction func didSwitchAll(_ sender: Any) {
    if selectAllSwitch.isOn {
      filters = FilterHelper.getAllFilterNames()
    } else {
      filters = []
    }
    
    tableView.reloadData()
  }
  
  func containSameElements<T: Comparable>(_ array1: [T], _ array2: [T]) -> Bool {
    guard array1.count == array2.count else {
      return false // No need to sorting if they already have different counts
    }
    
    return array1.sorted() == array2.sorted()
  }
  
  func getFilterEntry(for indexPath: IndexPath) -> (tag: String, name: String) {
    let key = getName(for: indexPath.section)
    let items = tags[key]!
    let itemKey = Globals.MapFilter.tagsSorted[indexPath.row]
    return (itemKey, items[itemKey]!)
  }
  
  func getName(for section: Int) -> String {
    let keys = Array(tags.keys)
    let key = keys[section]
    return key
  }
}

extension FilterViewController : UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return tags.keys.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let keys = Array(tags.keys)
    let key = keys[section]
    
    if let items = tags[key] {
      return items.count
    }
    
    return 0
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = Bundle.main.loadNibNamed(FilterSectionHeaderView.nibName,
                                        owner: self,
                                        options: nil)?.first as! FilterSectionHeaderView
    
    let keys = Array(tags.keys)
    let key = keys[section]

    view.sectionTitleLabel.text = key
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if Array(tags.keys)[section] == "" {
      return 0
    }
    return 45
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FilterTableViewCell.identifier) as! FilterTableViewCell
    
    let filterEntry = getFilterEntry(for: indexPath)
    cell.filterTag = filterEntry.tag
    cell.filterNameLabel.text = filterEntry.name
    
    var isFilterEnabled = false
    if filters.contains(filterEntry.tag) {
      isFilterEnabled = true
    }
    cell.enableSwitch.isOn = isFilterEnabled
    
    cell.delegate = self
    
    return cell
  }
}

extension FilterViewController : FilterTableViewCellDelegate {
  func didAddFilter(tag: String) {
    filters.append(tag)
  }
  
  func didRemoveFilter(tag: String) {
    filters = filters.filter() { $0 != tag }
  }
}

extension FilterViewController : UITableViewDelegate {
  
}
