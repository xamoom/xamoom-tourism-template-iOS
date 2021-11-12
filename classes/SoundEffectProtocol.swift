//
//  SoundEffectProtocol.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation
import AVFoundation

protocol SoundEffectProtocol: AnyObject {
    var audioPlayer: AVAudioPlayer? { get set }
}

extension SoundEffectProtocol {
    func playSound(named: String) {
        let path = Bundle.main.path(forResource: named, ofType: nil)!
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            // couldn't load file :(
        }
    }
}
