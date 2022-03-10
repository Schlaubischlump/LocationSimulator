//
//  String+Exentsion.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.01.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

import Foundation

// MARK: Localizable
public protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    public var localized: String {
        return NSLocalizedString(self, comment: "")
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
