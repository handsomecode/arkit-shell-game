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

/**
 Represents algebraic Permutation - https://en.wikipedia.org/wiki/Permutation
 */
class Permutation: NSObject {
    private let array: [Int]
    
    var count: Int {
        return array.count
    }
    
    subscript(index: Int) -> Int {
        get {
            return array[index]
        }
    }
    
    init (_ permutation: [Int]) {
        array = permutation
    }
    
    /**
     Return the product of two permutations.
     
     Note: operation is not commutative. For example:
     - mult([1, 0, 2], [2, 1, 0]) = [1, 2, 0]
     - mult([2, 1, 0], [1, 0, 2]) = [2, 0, 1]
     
     - parameter a: The multiplicand, or left operand of permutation multiplication.
     - parameter b: The multiplier, or right operand of permutation multiplication.
    */
    static func mult(_ a: Permutation, _ b: Permutation) -> Permutation {
        if a.count != b.count {
            fatalError("multiplication of unequal sized permutations are not supported")
        }
        var resultArray = Array(0..<a.count)
        for index in 0..<resultArray.count {
            resultArray[index] = b[a[index]]
        }
        return Permutation(resultArray)
    }

    /**
     Returns the inverse of the specified permutation.
     
     Examples:
     * invert([1, 2, 0]) = [2, 0, 1]
     * invert([2, 0, 1]) = [1, 2, 0]
     
     - parameter a: The permutation to be inverted.
     */
    static func invert(_ a: Permutation) -> Permutation {
        var result = [Int](repeating: -1, count: a.count)
        for (index, value) in a.array.enumerated() {
            result[value] = index
        }
        return Permutation(result)
    }
    
    override var description : String {
        var result = "Permutation("
        for index in 0..<array.count {
            result = result + "\(index) > \(array[index])"
            if index < array.count - 1 {
                result += "; "
            }
        }
        return result + ")"
    }
}
