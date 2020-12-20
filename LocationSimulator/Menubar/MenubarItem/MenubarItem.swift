//
//  Constants.swift
//  LocationSimulator
//
//  Created by David Klopp on 15.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
import AppKit

/// Protocol which all MenubarItems have to conform to
protocol MenubarItem {
    var rawValue: Int { get }

    // Reference to this menu.
    static var menu: NSMenu? { get }

    // Enable or disable the menu bar item.
    func setEnabled(_ enabled: Bool)
    func enable()
    func disable()
}

extension MenubarItem {
    func setEnabled(_ enabled: Bool) {
        Self.menu?.item(withTag: self.rawValue)?.isEnabled = enabled
    }

    func enable() {
        self.setEnabled(true)
    }

    func disable() {
        self.setEnabled(false)
    }
}
