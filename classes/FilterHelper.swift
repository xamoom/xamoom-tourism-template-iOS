//
//  FilterHelper.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 28/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import Foundation

class FilterHelper {
  
  public static func getAllFilterNames() -> [String] {
    var filters: [String] = []
    
    let tags = Globals.MapFilter.tags
    let keys = Array(tags.keys)
    for key in keys {
      if let keyDict = tags[key] {
        filters.append(contentsOf: Array(keyDict.keys))
      }
    }
    
    return filters
  }

}
