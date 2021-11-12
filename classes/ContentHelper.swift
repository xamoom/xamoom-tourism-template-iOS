//
//  ContentHelper.swift
//  kollitsch-art
//
//  Created by Raphael Seher on 27/02/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

class ContentHelper: NSObject {

  static func addContentDescription(content: XMMContent) -> XMMContent {
    var indexToInsert = 0
    
    // spaceblock is inserted to have more space between the bouncy headerImage
    // and the first textBlock. Workaround so that I don't have to change the
    // code in the XMMContentBlocks for displaying the first text
    let spaceBlock = XMMContentBlock()
    spaceBlock.blockType = 00
    spaceBlock.title = nil
    spaceBlock.text = nil
    content.contentBlocks.insert(spaceBlock, at: indexToInsert)
    indexToInsert = indexToInsert + 1
    
    let titleBlock = XMMContentBlock()
    titleBlock.blockType = 100
    titleBlock.title = content.title
    titleBlock.text = content.contentDescription
    content.contentBlocks.insert(titleBlock, at: indexToInsert)
    
    return content
  }
}
