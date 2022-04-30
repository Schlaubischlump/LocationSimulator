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

    // Change the menu bar item state.
    func setState(_ state: NSControl.StateValue)
    func on()
    func off()
}

extension MenubarItem {
    public var item: NSMenuItem? {
        return Self.menu?.item(withTag: self.rawValue)
    }

    public func setState(_ state: NSControl.StateValue) {
        self.item?.state = state
    }

    public func on() {
        self.setState(.on)
    }

    public func off() {
        self.setState(.off)
    }

    public func setEnabled(_ enabled: Bool) {
        self.item?.isEnabled = enabled
    }

    func enable() {
        self.setEnabled(true)
    }

    func disable() {
        self.setEnabled(false)
    }

    /// Trigger the action of the menu item.
    @discardableResult
    func triggerAction() -> Bool {
        if let item = self.item, let index = Self.menu?.index(of: item) {
            Self.menu?.performActionForItem(at: index)
            return true
        }
        return false
    }
}
