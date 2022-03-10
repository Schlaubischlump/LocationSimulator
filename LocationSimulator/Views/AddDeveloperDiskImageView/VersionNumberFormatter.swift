//
//  VersionFormatter.swift
//  LocationSimulator
//
//  Created by David Klopp on 09.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class VersionNumberFormatter: Formatter {

    private let maxMajorDigits = 2

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func string(for obj: Any?) -> String? {
        if let string = obj as? String {
            return string
        }
        return nil
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                                 for string: String,
                                 errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
            obj?.pointee = string as AnyObject
            return true
    }

    override func isPartialStringValid(_ partialString: String,
                                       newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                       errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.isEmpty {
            return true
        }

        // If the user entered a single or two digits and did not start with a zero
        if partialString.count <= self.maxMajorDigits && Int(partialString) != nil {
            if partialString != "0" {
                return true
            }
            NSSound.beep()
            return false
        }

        // Allow the user to add a dot after the first number
        let numberString = partialString.dropLast()
        if partialString.last == "." && numberString.count <= self.maxMajorDigits && Int(numberString) != nil {
            return true
        }

        // Match version numbers
        if !partialString.isVersionString {
            NSSound.beep()
            return false
        }

        return true
    }
}
