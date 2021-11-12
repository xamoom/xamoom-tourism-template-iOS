//
//  ContentViewControllerProtocol.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

protocol ContentViewControllerProtocol: UIViewController {
    var contentId: String? { get set }
    func createContentVC() -> ContentViewControllerProtocol
}
