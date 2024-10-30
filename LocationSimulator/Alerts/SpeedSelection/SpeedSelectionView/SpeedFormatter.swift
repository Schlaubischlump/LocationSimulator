//
//  CoordinateFormatter.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

/// Generic speed formatter subclass to match double values between min and max value.
class SpeedFormatter: NumberFormatter, @unchecked Sendable {

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
        self.minimumIntegerDigits = 1
        self.maximumFractionDigits = 1
        self.minimumFractionDigits = 1
        self.decimalSeparator = "."
        self.minimum = NSNumber(value: kMinSpeed)
        self.maximum = NSNumber(value: kMaxSpeed)
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

        // check that the double value is valid
        if let num = Float(partialString) {
            if num < self.minimum!.floatValue || num > self.maximum!.floatValue {
                NSSound.beep()
                return false
            }
        }

        return true
    }
}
