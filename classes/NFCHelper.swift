//
//  NFCHelper.swift
//  tourismtemplate
//
//  Created by Thomas Krainz-Mischitz on 17.01.19.
//  Copyright © 2019 xamoom GmbH. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 11.0, *)
class NFCHelper : NSObject {
  var session: NFCNDEFReaderSession!
  var onNFCResult: ((String?, Error?) -> ())?
  
  override init() {
    super.init()
    session = NFCNDEFReaderSession(delegate: self, queue: nil,
                                   invalidateAfterFirstRead: true)
  }
  
  func startNFCScanning() {
    if (!session.isReady) {
      recreateSession()
    }
    session?.begin()
  }
  
  func recreateSession() {
    session = NFCNDEFReaderSession(delegate: self, queue: nil,
                                   invalidateAfterFirstRead: true)
  }
}

@available(iOS 11.0, *)
extension NFCHelper : NFCNDEFReaderSessionDelegate {
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    guard let onNFCResult = onNFCResult else {
      return
    }
    
    if (error._code == 204) {
      return
    }
    
    onNFCResult(nil, error)
  }
  
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    for message in messages {
      print(" - \(message.records.count) Records:")
      for record in message.records {
        print("\t- TNF (TypeNameFormat): \(record.typeNameFormat))")
        print("\t- Payload: \(String(data: record.payload, encoding: .utf8)!)")
        print("\t- Type: \(record.type)")
        print("\t- Identifier: \(record.identifier)\n")
      }
    }
    
    guard let onNFCResult = onNFCResult else {
      return
    }
    
    var host = ""
    if let path = Bundle.main.path(forResource: "gen", ofType: "plist"),
      let myDict = NSDictionary(contentsOfFile: path) {
      host = myDict["custom-webclient-host"] as! String
    }
    
    for message in messages {
      for record in message.records {
        if(record.payload.count > 0 && record.typeNameFormat == .nfcWellKnown) {
          print("Type: \(record.typeNameFormat)")
          if let payloadString = String.init(data: record.payload, encoding: .utf8) {
            if payloadString.contains("content/") || payloadString.contains(host) {
                let index = payloadString.index(payloadString.startIndex, offsetBy: 1)
                let nfcResultString = payloadString.substring(from: index)
                let result = String.init(format: "%@%@", "https://", nfcResultString)
                let url = URL(string: result)
                let urlHost = url?.host
            
                if urlHost != nil {
                onNFCResult(result, nil)
                } else {
                onNFCResult(nfcResultString, nil)
                }
            } else {
                let index = payloadString.index(payloadString.startIndex, offsetBy: 3)
                let nfcResultString = payloadString.substring(from: index)
                onNFCResult(nfcResultString, nil)
            }
          }
        }
      }
    }
  }
}
