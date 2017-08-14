//
//  AudioPlayer.swift
//  ShellGame
//
//  Created by Andrey Arzhannikov on 14.08.17.
//  Copyright © 2017 Handsome. All rights reserved.
//

import Foundation
import SceneKit

class AudioPlayer {
    
    enum Sound {
        case success
        case fail
    }
    
    static let shared = AudioPlayer()
    
    private lazy var successAudioSource: SCNAudioSource = {
        let sound = SCNAudioSource(fileNamed: "art.scnassets/sounds/success.wav")!
        sound.volume = 1
        sound.isPositional = true
        sound.shouldStream = false
        sound.load()
        return sound
    }()
    
    private lazy var failAudioSource: SCNAudioSource = {
        let sound = SCNAudioSource(fileNamed: "art.scnassets/sounds/fail.mp3")!
        sound.volume = 1
        sound.isPositional = true
        sound.shouldStream = false
        sound.load()
        return sound
    }()
    
    private init() {}
    
    func playSound(_ sound: Sound, on node: SCNNode) {
        let action = SCNAction.playAudio(audioSourceForSound(sound),
                                         waitForCompletion: false)
        node.runAction(action)
    }
    
    private func audioSourceForSound(_ sound: Sound) -> SCNAudioSource {
        switch sound {
        case .success:
            return successAudioSource
        case .fail:
            return failAudioSource
        }
    }
}
