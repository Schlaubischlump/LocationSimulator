//
//  FileManager+License.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation

extension FileManager {
    /// Get all dependeny names with their corresponding license text in a dictionary.
    /// - Return: license name with the corresponding license text as Dictionary
    public func getLicenses() -> [String: String] {
        if let plistPath = Bundle.main.path(forResource: "Licenses", ofType: "plist") {
            let licenseDict = NSDictionary(contentsOfFile: plistPath) as? [String: String]
            return licenseDict ?? [:]
        } else {
            logError("Licenses: Could not be loaded.")
        }
        return [:]
    }
}
