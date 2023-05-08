//
//  RecentLocationMenuBarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CoreLocation

let kMaxRecentItems: Int = 10
let kRecentLocationKey: String = "com.schlaubischlump.locationsimulator.recentlocations"

/// Simple codable struct to store the information about a location.
class Location: NSObject, Codable {
    var name: String
    var lat: Double
    var long: Double

    init(name: String, lat: Double, long: Double) {
        self.name = name
        self.lat = lat
        self.long = long
    }
}

/// Extend the UserDefaults with all keys relevant for the RecentLocation submenu.
extension UserDefaults {
    @objc dynamic var recentLocations: [Location] {
        get {
            guard let storedLoc = self.array(forKey: kRecentLocationKey) as? [Data]  else { return [] }
            let decoder = PropertyListDecoder()
            return storedLoc.compactMap { try? decoder.decode(Location.self, from: $0) }
        }
        set {
            let encoder = PropertyListEncoder()
            self.setValue(newValue.compactMap { try? encoder.encode($0) }, forKey: kRecentLocationKey)
        }
    }

    /// Register the default values.
    func registerRecentLocationDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kRecentLocationKey: [Location]()
        ])
    }
}

/// Enum to represent the Recent Locations submenu.
enum RecentLocationMenubarItem: Int, CaseIterable, MenubarItem {
    case separator = -1
    case clearMenu = -2

    static public var menu: NSMenu? {
        let recentLocationSubmenuTag: Int = NavigationMenubarItem.recentLocation.rawValue
        let navigationMenu = NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu
        return navigationMenu?.item(withTag: recentLocationSubmenuTag)?.submenu
    }

    // MARK: - Manage recent locations

    /// Add a new menubar item for a given Location instance.
    /// - Parameter loc: location instance
    static func addLocationMenuItem(_ loc: Location) {
        guard let delegate = NSApp.delegate as? AppDelegate,
              let menubarController = delegate.menubarController else { return }
        // Add a callback function to the menuController.
        let menuItem = NSMenuItem(title: loc.name, action: nil, keyEquivalent: "")
        menuItem.action = #selector(menubarController.selectRecentLocation(_:))
        menuItem.target = menubarController
        menuItem.isEnabled = true
        RecentLocationMenubarItem.menu?.insertItem(menuItem, at: 0)
        // Enable the clear menu if required
        if let menu = RecentLocationMenubarItem.menu, menu.items.count > RecentLocationMenubarItem.allCases.count {
            RecentLocationMenubarItem.clearMenu.enable()
        }
    }

    /// Remove a location menu item at a given index.
    /// - Parameter index: the index of the item to remove.
    static func removeLocationMenuItem(at index: Int) {
        guard let menu = RecentLocationMenubarItem.menu else { return }
        // Make sure the index is within the range of possible menu items. Otherwise menu.item(at:) will crash.
        guard index >= 0 && index < menu.items.count else { return }
        // We can not remove statis menu bar entries, such as the clear menu or the separator.
        if let tag = menu.item(at: index)?.tag, RecentLocationMenubarItem(rawValue: tag) != nil {
            return
        }
        // Remove the item
        menu.removeItem(at: index)
        // Disable the clear menu if the last item was removed.
        if menu.items.count <= RecentLocationMenubarItem.allCases.count {
            RecentLocationMenubarItem.clearMenu.disable()
        }
    }

    /// Clear all recent locations from the menubar.
    static func clearLocationMenuItems() {
        guard let menu = RecentLocationMenubarItem.menu else { return }
        for _ in 0..<menu.items.count {
            RecentLocationMenubarItem.removeLocationMenuItem(at: 0)
        }
    }
}
