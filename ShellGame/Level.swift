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

struct LevelStep {
    typealias Speed = Float
    
    let permutation: Permutation
    let speed: Speed
    let clockwise: Set<Int>
    
    init(permutation: Permutation, speed: Speed = 1.0, clockwise: Set<Int> = Set<Int>()) {
        self.permutation = permutation
        self.speed = speed
        self.clockwise = clockwise
    }
}

struct Level {
    let steps: [LevelStep]
}
