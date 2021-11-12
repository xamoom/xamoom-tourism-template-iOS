//
//  GuideInteractionProtocol.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

protocol GuideInteractionProtocol{
    func didClick(itemPosition: Int, cellIdentifier: GuideCellDisplayType)
}
