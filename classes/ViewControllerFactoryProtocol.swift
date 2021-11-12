//
//  ViewControllerFactoryProtocol.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation
import UIKit

protocol ViewControllerFactoryProtocol {
    func makeHomeViewController() -> HomeViewController
    func makeMapViewController() -> MapViewController
    func makeScanViewController() -> ScanViewController
    func makeContentViewController() -> ContentViewController
    func makeSettingsViewController() -> SettingsViewController
    func makeOnboardViewController(nextController: UIViewController) -> OnboardViewController
    func makeFilterViewController() -> FilterViewController
}

class ViewControllerFactory: ViewControllerFactoryProtocol {
    
    func makeHomeViewController() -> HomeViewController {
        let homeViewController = HomeViewController(nibName: "HomeViewController", bundle: nil)
        homeViewController.title = NSLocalizedString("tabbar.home", comment: "")
        homeViewController.tabBarItem.image = UIImage(named: "home")?
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        homeViewController.tabBarItem.accessibilityIdentifier = "Home Tabbar Item"
        homeViewController.tabBarItem.selectedImage = UIImage(named: "home_filled")?.withRenderingMode(.alwaysTemplate)
        
        return homeViewController
    }
    
    func makeQuizHomeViewController() -> QuizHomeViewController {
        let homeViewController = QuizHomeViewController(nibName: "QuizHomeViewController", bundle: nil)
        homeViewController.title = NSLocalizedString("tabbar.home", comment: "")
        homeViewController.tabBarItem.image = UIImage(named: "home")?
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        homeViewController.tabBarItem.accessibilityIdentifier = "Home Tabbar Item"
        homeViewController.tabBarItem.selectedImage = UIImage(named: "home_filled")?.withRenderingMode(.alwaysTemplate)
        
        return homeViewController
    }
    
    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController(nibName: "MapViewController", bundle: nil)
        mapViewController.title = NSLocalizedString("tabbar.map", comment: "")
        mapViewController.tabBarItem.image = UIImage(named: "map")?
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        mapViewController.tabBarItem.accessibilityIdentifier = "Map Tabbar Item"
        mapViewController.tabBarItem.selectedImage = UIImage(named: "map_filled")?.withRenderingMode(.alwaysTemplate)
        
        return mapViewController
    }

    func makeScanViewController() -> ScanViewController {
        let scanViewController = ScanViewController(nibName: "ScanViewController", bundle: nil)
        scanViewController.title = NSLocalizedString("tabbar.scan", comment: "")
        scanViewController.tabBarItem.image = UIImage(named: "scan")?
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        scanViewController.tabBarItem.selectedImage = UIImage(named: "scan_filled")?.withRenderingMode(.alwaysTemplate)
        
        return scanViewController
    }

    func makeContentViewController() -> ContentViewController {
        let infoViewController = ContentViewController(nibName: "ContentViewController", bundle: nil)
        infoViewController.title = NSLocalizedString("tabbar.info", comment: "")
        infoViewController.tabBarItem.image = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        infoViewController.tabBarItem.accessibilityIdentifier = "Info Tabbar Item"
        infoViewController.tabBarItem.selectedImage = UIImage(named: "info_filled")?.withRenderingMode(.alwaysTemplate)
        infoViewController.tag = Globals.Tag.infoSite
        
        return infoViewController
    }
    
    func makeQuizContentViewController() -> QuizContentViewController {
        let infoViewController = QuizContentViewController(nibName: "QuizContentViewController", bundle: nil)
        infoViewController.title = NSLocalizedString("tabbar.info", comment: "")
        infoViewController.tabBarItem.image = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        infoViewController.tabBarItem.accessibilityIdentifier = "Info Tabbar Item"
        infoViewController.tabBarItem.selectedImage = UIImage(named: "info_filled")?.withRenderingMode(.alwaysTemplate)
        infoViewController.tag = Globals.Tag.infoSite
        
        return infoViewController
    }

    func makeSettingsViewController() -> SettingsViewController {
        let settingsViewController = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        settingsViewController.title = NSLocalizedString("tabbar.settings", comment: "")
        settingsViewController.tabBarItem.image = UIImage(named: "setting")?
          .imageWithColor(color1: Globals.Color.tabbarSelected)
          .withRenderingMode(.alwaysOriginal)
        settingsViewController.tabBarItem.selectedImage = UIImage(named: "setting_filled")?.withRenderingMode(.alwaysTemplate)
        
        return settingsViewController
    }

    func makeOnboardViewController(nextController: UIViewController) -> OnboardViewController {
        let onboardController = OnboardViewController()
        onboardController.nextControllerToLoad = nextController
        
        return onboardController
    }

    func makeFilterViewController() -> FilterViewController {
        let filterViewController = FilterViewController(nibName: "FilterViewController", bundle: nil)
        return filterViewController
    }
    
}

