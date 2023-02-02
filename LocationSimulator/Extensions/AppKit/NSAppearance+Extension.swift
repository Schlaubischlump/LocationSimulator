//
//  NSAppearance+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 01.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import AppKit

extension NSAppearance {
    var isDark: Bool {
        if #available(macOS 10.14, *) {
            return self.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }
        return false
    }
}
