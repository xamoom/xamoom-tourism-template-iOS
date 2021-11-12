//
//  Array+Extensions.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 03.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
    
    func removingDuplicates<T: Hashable>(byKey key: (Element) -> T)  -> [Element] {
            var result = [Element]()
            var seen = Set<T>()
            for value in self {
                if seen.insert(key(value)).inserted {
                    result.append(value)
                }
            }
            return result
        }
}
