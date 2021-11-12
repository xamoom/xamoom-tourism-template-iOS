//
//  SettingsViewController.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 28/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit

enum SettingsType {
  case Filter
  case Select
  case Language
  case Id
}

enum Setting {
  enum Navigation {
    case Walking
    case Driving
    case PublicTransport
  }
  enum Notification {
    case Notification
    case Sound
    case Vibrant
  }
  enum Id {
    case EphemeralId
  }
  
  case Nav(Navigation)
}

class SettingsViewController: UIViewController {
  public static let identifier = "SettingsViewController"
  
  let normalCellIdentifier = "NormalCellIdentifier"
  let subtitleCellIdentifier = "SubtitleCellIdentifier"
  var settingHeaderTitles = [SettingsType.Filter, SettingsType.Select, SettingsType.Id]
  var settings = [[Setting.Notification.Notification, Setting.Notification.Sound],
                  [Setting.Navigation.Walking, Setting.Navigation.Driving, Setting.Navigation.PublicTransport], [Setting.Id.EphemeralId]]
  private var showId: Bool = false
  private var showIdCopiedNotification = false
  private var numberOfTouchOnId = 0
    
  @IBOutlet weak var tableView: UITableView!
  
  var selectedNavigation: IndexPath?
  var selectedRow: IndexPath?
  var notificationOff: Bool = true
  var notificationSoundMuted: Bool = false
  var notificationVibrant: Bool = true
  var ephemeralId: String?
  var userLanguage: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Settings screen")
    AnalyticsHelper.reportContentView(contentName: "Settings",
                                      contentType: Globals.Analytics.contentTypeScreen,
                                      contentId: "",
                                      customAttributes: nil)
  
    loadSettings()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: Bundle.main),
                       forCellReuseIdentifier: SwitchTableViewCell.identifier)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: normalCellIdentifier)
  }
  
  override func viewWillAppear(_ animated: Bool) {
      UIApplication.shared.statusBarStyle = .lightContent
      self.navigationController?.isNavigationBarHidden = false
      showNavigationBar()
    
     if ApiHelper.shared.system == nil {
       ApiHelper.shared.downloadSystem(completion: {system in
         if let system = system {
           ApiHelper.shared.downloadSettings(withID: system.id as! String, completion: { _ in
             self.loadSettings()
             self.tableView.reloadData()
           })
         }
       })
     } else if ApiHelper.shared.settings == nil {
         if let system = ApiHelper.shared.system {
             ApiHelper.shared.downloadSettings(withID: system.id as! String, completion: { _ in
               self.loadSettings()
               self.tableView.reloadData()
             })
         }
     }
    
    showId = false
    showIdCopiedNotification = false
    numberOfTouchOnId = 0
    tableView.reloadData()
    addTableViewFooter()
  }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 15.0, *) {
            let appearanceStandart = UINavigationBarAppearance()
            appearanceStandart.configureWithOpaqueBackground()
            appearanceStandart.backgroundColor = Globals.Color.primaryColor
            appearanceStandart.shadowColor = .clear
            let appearanceScroll = UINavigationBarAppearance()
            appearanceScroll.configureWithOpaqueBackground()
            appearanceScroll.backgroundColor = nil
            appearanceScroll.shadowColor = .clear
            self.navigationController?.navigationBar.standardAppearance = appearanceStandart
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearanceScroll
        }
    }
    
    private func showNavigationBar() {
        self.navigationItem.title = NSLocalizedString("tabbar.settings", comment: "")
        
        navigationController?.navigationBar.titleTextAttributes =
          [NSAttributedStringKey.foregroundColor:Globals.Color.tabbarSelected]
        
        navigationController?.navigationBar.tintColor = Globals.Color.tabbarSelected
        navigationController?.navigationBar.setBackgroundImage(nil,
                                                               for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.isTranslucent = true
        UIApplication.shared.statusBarStyle = Globals.Color.barFontColor.isDark ? .default : .lightContent
        
        if Globals.isBackgroundImage.elementsEqual("true") {
            navigationController?.navigationBar.setBackgroundImage(UIImage(named: "background_image"), for: .default)
        }
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Globals.isBackgroundImage == "true" ? UIColor(patternImage: UIImage(named: "background_image")!) : Globals.Color.primaryColor
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        
        UIApplication.shared.statusBarStyle = .lightContent
    }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func addTableViewFooter() {
    let footerView = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width:self.view.frame.size.width,
                                          height: 10))
    tableView.tableFooterView = footerView
  }
  
  func loadSettings() {
    let userDefaults = UserDefaults.standard
    notificationOff = userDefaults.bool(forKey: Globals.Settings.notificationsOff)
    notificationSoundMuted = userDefaults.bool(forKey: Globals.Settings.notificationSoundMuted)
    notificationVibrant = userDefaults.bool(forKey: Globals.Settings.notificationVibrant)
    let navigationWay = userDefaults.integer(forKey: Globals.Settings.navigationKey)
    selectedRow = IndexPath(row: navigationWay, section: 1)
    ephemeralId = userDefaults.string(forKey: "com.xamoom.EphemeralId")
    userLanguage = userDefaults.string(forKey: Globals.Settings.languageKey) ?? ApiHelper.shared.api.language ?? "en"
    
    if let systemSettings = ApiHelper.shared.settings, let languagesMutableArray = systemSettings.languages, systemSettings.isLanguagePickerEnabled {
      let languages = languagesMutableArray as NSArray as? [String] ?? []
      
      if !languages.isEmpty {
        settingHeaderTitles.insert(SettingsType.Language, at: 2)
        settings.insert(languages, at: 2)
      }
      
      if !languages.contains(userLanguage!) {
        userLanguage = "en"
      }
    }
  }
  
  func getSetting(for indexPath: IndexPath) -> Any? {
    let key = getSettingType(for: indexPath.section)
    let items = settings[indexPath.section]
    let itemKey = items[indexPath.row]
    return itemKey
  }
  
  func getNavigationSetting(for indexPath: IndexPath) -> Setting.Navigation {
    return getSetting(for: indexPath) as! Setting.Navigation
  }
  
  func getNotificationSetting(for indexPath: IndexPath) -> Setting.Notification {
    return getSetting(for: indexPath) as! Setting.Notification
  }
  
  func getSettingType(for section: Int) -> SettingsType {
    let keys = settingHeaderTitles
    let type = keys[section]
    return type
  }
  
  func getSettingName(indexPath: IndexPath) -> String {
    if getSettingType(for: indexPath.section) == .Select {
      let setting = getNavigationSetting(for: indexPath)
      
      switch (setting) {
      case .Walking:
        return NSLocalizedString("settingsViewController.setting.navigation.walking", comment: "")
      case .Driving:
        return NSLocalizedString("settingsViewController.setting.navigation.driving", comment: "")
      case .PublicTransport:
        return NSLocalizedString("settingsViewController.setting.navigation.publicTransport", comment: "")
      }
    }
    
    if getSettingType(for: indexPath.section) == .Language {
      return getSetting(for: indexPath) as! String
    }
    
    if getSettingType(for: indexPath.section) == .Filter {
      let setting = getNotificationSetting(for: indexPath)
      switch (setting) {
      case .Notification:
        return NSLocalizedString("settingsViewController.setting.notification", comment: "")
      case .Sound:
        return NSLocalizedString("settingsViewController.setting.notification.sound", comment: "")
      case .Vibrant:
        return NSLocalizedString("settingsViewController.setting.notification.vibrant", comment: "")
      }
    }
    if getSettingType(for: indexPath.section) == .Id {
        return "Id"
    }
    
    return "Not found";
  }
  
  func getSettingHeaderName(for section: Int) -> String? {
    if getSettingType(for: section) == .Filter {
      return NSLocalizedString("settingsViewController.setting.notification.header", comment: "")
    }
    
    if getSettingType(for: section) == .Language {
      return NSLocalizedString("settingsViewController.setting.language.header", comment: "")
    }
    
    if getSettingType(for: section) == .Select {
      return NSLocalizedString("settingsViewController.setting.navigation.header", comment: "")
    }
    
    if getSettingType(for: section) == .Id {
        return nil
    }
    
    return "Not found";
  }
  
  func numberOfSettings() -> Int {
    var count = 0
    for setting in settings {
      count = count + setting.count
    }
    return count
  }
    
    @objc func onCellTouch(){
        numberOfTouchOnId += 1
        if numberOfTouchOnId == 7 {
            showId = true
            tableView.reloadData()
        }
        if numberOfTouchOnId == 8 {
            UIPasteboard.general.string = ephemeralId
            showIdCopiedNotification = true
            tableView.reloadData()        }
        
        }
    
}


extension SettingsViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return getSettingHeaderName(for: section)
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return settings.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let setting = settings[section]
    return setting.count
  }
    
    
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if getSettingType(for: indexPath.section) == SettingsType.Id {
            onCellTouch()
        }
        return indexPath
  }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if getSettingType(for: indexPath.section) == SettingsType.Id {
           return CGFloat(200)
        }
        return CGFloat(44)
    }
    
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?
    
    if getSettingType(for: indexPath.section) == SettingsType.Filter {
      let switchCell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.identifier) as! SwitchTableViewCell
      switchCell.delegate = self
      switchCell.cellLabel.text = getSettingName(indexPath: indexPath)
      switchCell.setting = getNotificationSetting(for: indexPath)
      if switchCell.setting == Setting.Notification.Sound {
        switchCell.cellSwitch.isOn = !notificationSoundMuted
      } else if switchCell.setting == Setting.Notification.Vibrant {
        switchCell.cellSwitch.isOn = notificationVibrant
      } else if switchCell.setting == Setting.Notification.Notification {
        switchCell.cellSwitch.isOn = !notificationOff
      }
      cell = switchCell
        
    } else if getSettingType(for: indexPath.section) == SettingsType.Language {
      
      cell = tableView.dequeueReusableCell(withIdentifier: subtitleCellIdentifier)
      if (cell == nil)
      {
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: subtitleCellIdentifier)
      }
      
      let languageCode = getSettingName(indexPath: indexPath)
      let languageInfo = Globals.Languages.languages.first(where: { $0.0 == languageCode.uppercased() })
      
      cell?.textLabel?.text = languageInfo?.3 ?? languageCode
      cell?.detailTextLabel?.text = languageInfo?.2 ?? languageCode
      
      
      if getSettingName(indexPath: indexPath) == userLanguage {
        cell?.tintColor = Globals.Color.primaryColor
        cell?.accessoryType = .checkmark
      } else {
        cell?.accessoryType = .none
      }
      
      return cell!
      
    } else if getSettingType(for: indexPath.section) == SettingsType.Id {
      cell = tableView.dequeueReusableCell(withIdentifier: normalCellIdentifier)
      cell?.selectionStyle = .none
      cell?.textLabel?.numberOfLines = 10
      if showIdCopiedNotification {
        cell?.textLabel?.text = "\(ephemeralId!) \n Copied!"
      } else if showId {
        cell?.textLabel?.text = ephemeralId
      } else {
        cell?.textLabel?.text = ""
      }
        
    } else {
      cell = tableView.dequeueReusableCell(withIdentifier: normalCellIdentifier)
      cell?.selectionStyle = .none

      cell?.textLabel?.text = getSettingName(indexPath: indexPath)
      
      if #available(iOS 13.0, *) {
        let style = UITraitCollection.current.userInterfaceStyle
        if (style == .dark) {
          cell?.tintColor = UIColor.white
        } else {
          cell?.tintColor = UIColor.black
        }
      } else {
        cell?.tintColor = UIColor.black
      }
      
      if indexPath == selectedRow {
        cell?.tintColor = Globals.Color.primaryColor
        cell?.accessoryType = .checkmark
      } else {
        cell?.accessoryType = .none
      }
    }
    
    return cell!
    
  }
}

extension SettingsViewController : UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if getSettingType(for: indexPath.section) == SettingsType.Select {
      selectedRow = indexPath
      
      UserDefaults.standard.set(indexPath.row, forKey: Globals.Settings.navigationKey)
      UserDefaults.standard.synchronize()
      
      tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: UITableViewRowAnimation.none)
    }
    
    if getSettingType(for: indexPath.section) == SettingsType.Language {
      let languageCode = getSettingName(indexPath: indexPath)
      userLanguage = languageCode
      UserDefaults.standard.set(languageCode, forKey: Globals.Settings.languageKey)
      UserDefaults.standard.synchronize()
      ApiHelper.shared.api.language = languageCode
      Bundle.setLanguage(languageCode)
      
      tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: UITableViewRowAnimation.none)
      
      let delegate = UIApplication.shared.delegate as! AppDelegate
      let tabbarController = delegate.setupNavigationStack()
      tabbarController.selectedIndex = 4
      delegate.window?.rootViewController = tabbarController
      delegate.window?.makeKeyAndVisible()
      
    }
  }
}

extension SettingsViewController : SwitchTableViewCellDelegate {
  func didChange(setting: Setting.Notification, to isOn: Bool) {
    
    if setting == .Sound {
      UserDefaults.standard.set(!isOn, forKey: Globals.Settings.notificationSoundMuted)
      ApiHelper.shared.api.pushSound = isOn
    }
    
    if setting == .Vibrant {
      UserDefaults.standard.set(isOn, forKey: Globals.Settings.notificationVibrant)
    }
    
    if setting == .Notification {
      UserDefaults.standard.set(!isOn, forKey: Globals.Settings.notificationsOff)
      ApiHelper.shared.api.noNotification = !isOn
    }
    
    ApiHelper.shared.pushDevice(instantPush: true)
    
    UserDefaults.standard.synchronize()
  }
}
