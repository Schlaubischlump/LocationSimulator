//
//  String+Exentsion.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.01.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

import Foundation
import AppKit

// MARK: Localizable
public protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    /// Localize a string for the current language and fallback to the base localization if a key is missing.
    public var localized: String {
        let localized = NSLocalizedString(self, comment: "")

        if self != localized {
            return localized
        }

        // Use the base localization as fallback for missing keys
        guard let path = Bundle.main.path(forResource: "Base", ofType: "lproj"), let bundle = Bundle(path: path) else {
            return localized
        }

        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

// MARK: - Regex

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

// MARK: - Number

extension String {
    /// Currently we only allow version with the format major.minor. Normally apple does increase the minor number when
    /// changing the DeveloperDiskImage. We therefore ignore the revision in version numbers (major.minor.revision).
    var isVersionString: Bool {
        return self ~= "^\\d{1,2}\\.\\d{1,2}$"
    }
}

// MARK: - Size

extension String {
    public func fittingWidth(forFont font: NSFont) -> CGFloat {
        return (self as NSString).size(withAttributes: [.font: font]).width
    }
}
