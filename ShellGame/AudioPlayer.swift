//
// Copyright © 2017 Handsome.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
/////////////////////////////////////////////////////////////////////////////

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
