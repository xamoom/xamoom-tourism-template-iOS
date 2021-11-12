//
//  public protocol ImageSliderDelegate {   func didClick(content: XMMContent) ContentInteractionProtocol.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 19/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK

public protocol ContentInteractionProtocol{
  func removeEmptyCell(tag: String)
  func didClick(content: XMMContent, isBeacon: Bool)
}
