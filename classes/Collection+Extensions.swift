//
//  Collection+Extensions.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 17.07.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
   public subscript(safe index: Index) -> Iterator.Element? {
     return (startIndex <= index && index < endIndex) ? self[index] : nil
   }
}
