//
//  Array+Extension.swift
//  LocationSimulator2
//
//  Created by David Klopp on 23.09.20.
//

import Foundation

extension Array {
    /// Find the index of a new element, to insert it without breaking the order of the array.
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var low = 0
        var high = self.count - 1
        while low <= high {
            let mid = (low + high)/2
            if isOrderedBefore(self[mid], elem) {
                low = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                high = mid - 1
            } else {
                return mid
            }
        }
        return low
    }
}
