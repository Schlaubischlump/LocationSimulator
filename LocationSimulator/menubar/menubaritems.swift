//
//  Constants.swift
//  LocationSimulator
//
//  Created by David Klopp on 15.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
import AppKit
import CoreLocation

let kNavigationMenuTag: Int = 1

/// Enum to represent the main navigation menu
enum NavigationMenubarItem: Int {
    case walk                   = 0
    case cycle                  = 1
    case drive                  = 2
    case setLocation            = 4
    case toggleAutomove         = 6
    case moveUp                 = 8
    case moveDown               = 9
    case moveCounterclockwise   = 10
    case moveClockwise          = 11
    case stopNavigation         = 12
    case resetLocation          = 13
    case recentLocation         = 14

    static public var menu: NSMenu? {
        guard let navigationMenu = NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu else { return nil }
        return navigationMenu
    }

    // MARK: - Enable or disable a menubar item

    private func setEnabled(_ enabled: Bool) {
        NavigationMenubarItem.menu?.item(withTag: self.rawValue)?.isEnabled = enabled
    }

    func enable() {
        self.setEnabled(true)
    }

    func disable() {
        self.setEnabled(false)
    }
}

// MARK: - Recent Locations

struct Location: Codable {
    var name: String
    var lat: Double
    var long: Double

    init(name: String, lat: Double, long: Double) {
        self.name = name
        self.lat = lat
        self.long = long
    }
}

let kMaxRecentItems: Int = 10
let kRecentLocationUserDefaultKey: String = "RecentLocations"

/**
 Enum to represent the recent location submenu
 */
enum RecentLocationMenubarItem: Int {
    case clearMenu = 1

    static public var menu: NSMenu? {
        let recentLocationSubmenuTag: Int = NavigationMenubarItem.recentLocation.rawValue
        guard let navigationMenu = NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu else { return nil }
        guard let recentLocationMenu = navigationMenu.item(withTag: recentLocationSubmenuTag)?.submenu else {
            return nil
        }
        return recentLocationMenu
    }

    // MARK: - Enable or disable a menubar item

    private func setEnabled(_ enabled: Bool) {
        RecentLocationMenubarItem.menu?.item(withTag: self.rawValue)?.isEnabled = enabled
    }

    func enable() {
        self.setEnabled(true)
    }

    func disable() {
        self.setEnabled(false)
    }

    // MARK: - Manage recent locations

    /**
     Read all recent location from the UserDefaults.
     - Return: list of all recent locations
     */
    static func locations() -> [Location] {
        let defaults = UserDefaults.standard
        if let storedLoc = defaults.array(forKey: kRecentLocationUserDefaultKey) as? [Data] {
            // convert data to Location struct
            let decoder = PropertyListDecoder()
            return storedLoc.compactMap { data in
                return try? decoder.decode(Location.self, from: data)
            }
        }
        return []
    }

    /**
     Add a new location to the UserDefaults and the MenuBar.
     - Parameter coords: coordinates of the recent location
     */
    static func addLocation(_ coords: CLLocationCoordinate2D) {
        // load all entries and delete the last one if we have to many
        var recentLocations = RecentLocationMenubarItem.locations()

        // Make sure that we did not already store this location in the recent entries and if we do, then remove the
        // entry and call the remaining function to insert the item at the beginning. If the name of the location
        // has changed since the last teleportation this will guarantee that the information is updated.
        for index in 0..<recentLocations.count {
            let loc: Location = recentLocations[index]
            let locCoords = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
            if locCoords.distanceTo(coordinate: coords) < 0.005 {
                recentLocations.remove(at: index)
                RecentLocationMenubarItem.menu?.removeItem(at: index)
                break
            }
        }

        // add the new location to the UserDefaults and the menu
        coords.getLocationName { loc, name in
            // remove the last item if we exceed the maximum number
            if recentLocations.count >= kMaxRecentItems {
                _ = recentLocations.popLast()
                RecentLocationMenubarItem.menu?.removeItem(at: kMaxRecentItems-1)
            }

            // add new entry
            let loc = Location(name: name, lat: loc.coordinate.latitude, long: loc.coordinate.longitude)
            recentLocations.insert(loc, at: 0)

            // save the changes
            let encoder = PropertyListEncoder()
            let defaults = UserDefaults.standard
            defaults.set(recentLocations.compactMap { loc -> Data? in
                return try? encoder.encode(loc)
            }, forKey: kRecentLocationUserDefaultKey)
            defaults.synchronize()

            // add the menubaritem
            RecentLocationMenubarItem.addLocationMenuItem(loc)
            // enable the clear menu item
            RecentLocationMenubarItem.clearMenu.enable()
        }
    }

    /**
     Add a new menubar item for a given Location instance.
     - Parameter loc: location instance
     */
    static func addLocationMenuItem(_ loc: Location) {
        guard let delegate = NSApp.delegate as? AppDelegate else { return }
        let menuItem = NSMenuItem(title: loc.name, action: #selector(delegate.selectRecentLocation(_:)),
                                  keyEquivalent: "")
        menuItem.isEnabled = true
        RecentLocationMenubarItem.menu?.insertItem(menuItem, at: 0)
    }

    /**
     Clear all recent locations from the menu and the UserDefaults.
     */
    static func clearLocations() {
        // remove all saved entries
        let defaults = UserDefaults.standard
        defaults.set([], forKey: kRecentLocationUserDefaultKey)
        defaults.synchronize()

        // clear the menu entries (minus to because of the separator and the clear menu field)
        let numItems: Int = (RecentLocationMenubarItem.menu?.items.count)! - 2
        for _ in 0..<numItems {
            RecentLocationMenubarItem.menu?.removeItem(at: 0)
        }

        // disable the clear menu
        RecentLocationMenubarItem.clearMenu.disable()
    }
}
