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
