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

import UIKit
import SceneKit

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
}

extension Int {
    func sign() -> Int {
        return (self < 0 ? -1 : 1)
    }
}

extension Float {
    func sign() -> Float {
        return (self < 0 ? -1.0 : 1.0)
    }
}

extension Level {
    static func generate(number: Int) -> Level {
        
        func randomPermutation() -> Permutation {
            let random = arc4random_uniform(3)
            if random == 0 {
                return Permutation([1, 0, 2])
            } else if random == 1 {
                return Permutation([0, 2, 1])
            } else {
                return Permutation([2, 1, 0])
            }
        }
        let speed = 0.5 + log(1 + Float(number*number) / 2) / 5
        return Level(steps: (0..<number + 5).map { _ in
            let permutation = randomPermutation()
            var clockwise = Set<Int>()
            for from in 0..<permutation.count {
                let to = permutation[from]
                let toto = permutation[to]
                if (from < to && from == toto && arc4random_uniform(2) == 0) {
                    clockwise.insert(from)
                    clockwise.insert(to)
                }
            }
            return LevelStep(permutation: permutation, speed: speed, clockwise: clockwise)
        })
    }
}

extension SCNAction {
    
    class func single(action block: @escaping (SCNNode) -> Void) -> SCNAction {
        var executed = false
        return SCNAction.customAction(duration: 0.0) { node, _ in
            if !executed {
                block(node)
                executed = true
            }
        }
    }
    
    class func permutate(index: Int, with step: LevelStep, to distance: Float) -> SCNAction {
        let from = index
        let to = step.permutation[from]
        let toto = step.permutation[to]
        let halfDistance = distance * 0.5
        if to == from {
            return SCNAction.wait(duration: 0.0)
        }
        if toto == from {
            let prePivot = SCNAction.single() { node in
                let direction = Float((to - from).sign()) * cos(node.rotation.w).sign()
                let offset = direction * halfDistance * Float(abs(to - from))
                node.pivot = SCNMatrix4MakeTranslation(offset, 0.0, 0.0)
                node.localTranslate(by: SCNVector3(offset, 0.0, 0.0))
            }
            
            let pathLength = .pi * halfDistance * Float(abs(to - from))
            let duration = TimeInterval(pathLength / step.speed)
            let rotationDirection = CGFloat(step.clockwise.contains(from) ? -1 : 1)
            let rotate = SCNAction.rotate(by: .pi * rotationDirection, around: SCNVector3(0, 1, 0), duration: duration)
            
            let postPivot = SCNAction.single() { node in
                node.localTranslate(by: SCNVector3(-node.pivot.m41, 0.0, 0.0))
                node.pivot = SCNMatrix4Identity
            }
            
            return SCNAction.sequence([prePivot, rotate, postPivot])
        } else {
            fatalError("unsupported permutation. to be added later")
        }
    }
}

extension UIView {
    func roundCorners(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}
