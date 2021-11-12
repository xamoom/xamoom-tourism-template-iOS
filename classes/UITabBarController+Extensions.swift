//
//  UIViewController+Extensions.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 02.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

extension UITabBarController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        controller.dismissMenu(animated: true)
    }
}
