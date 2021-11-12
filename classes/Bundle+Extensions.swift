//
//  Bundle+Extensions.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 01.09.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

extension Bundle {
    public var smallIcon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.first {
            return UIImage(named: lastIcon)
        }
        return nil
    }
    
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
