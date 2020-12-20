//
//  CoordinateFormatter.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

/// String extenstion to match a String instance against a regex.
extension String {

    /// Operator overload to check if a String matches a regex.
    /// - Parameter lhs: String to check
    /// - Parameter rhs: regex to match
    /// - Return: True if lhs matches the regex rhs, False otherwise.
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
}

/// Generic coodinate formatter subclass to match coordinates strings. Do not use this class directly. Use the
/// corresponding `LatFormatter` and `LongFormatter` subclasses.
class CoodinateFormatter: NumberFormatter {

    override init() {
        super.init()
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.maximumIntegerDigits = 3
        self.minimumIntegerDigits = 3
        self.maximumFractionDigits = 7
        self.minimumFractionDigits = 7
        self.decimalSeparator = "."
    }

    override func isPartialStringValid(_ partialString: String,
                                       newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                       errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        if partialString.isEmpty {
            return true
        }

        // match float numbers
        if !(partialString ~= "^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$") {
            NSSound.beep()
            return false
        }

        // check that the coordinates are valid
        if let num = Float(partialString) {
            if num < self.minimum!.floatValue || num > self.maximum!.floatValue {
                NSSound.beep()
                return false
            }
        }

        return true
    }
}

/// Formatter to match latitude coordinates.
class LatFormatter: CoodinateFormatter {
    override func commonInit() {
        super.commonInit()
        self.minimum = -85
        self.maximum = 85
    }
}

/// Formatter to match longitude coordinates.
class LongFormatter: CoodinateFormatter {
    override func commonInit() {
        super.commonInit()
        self.minimum = -180
        self.maximum = 180
    }
}
