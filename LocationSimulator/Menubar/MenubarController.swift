//
//  MenubarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

enum MenubarState {
    // MARK: Device disconnected status

    /// No device currently active / ready to use. This can happen for the following reasons:
    /// - No device connected
    /// - DevDiskImage upload failed for selected device
    case disconnected

    // MARK: Device connected status

    /// Device is connected but there is no spoofed current location
    case connected
    /// Location is currently spoofed, with manual move
    case manual
    /// Location is currently spoofed, with auto move
    case auto
    /// Location is currently spoofed, with an active navigation
    case navigation

    // MARK: Items

    /// List with all MenubarItems to enable for this state.
    fileprivate var enabledItems: [MenubarItem] {
        var navigationItems: [NavigationMenubarItem] = [.walk, .cycle, .drive]
        let fileMenuItems: [FileMenubarItem] = [.openGPXFile]

        switch self {
        case .disconnected:
            return navigationItems
        case .connected:
            navigationItems += [.setLocation, .recentLocation, .useMacLocation]
            return navigationItems + fileMenuItems
        case .manual:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .moveClockwise, .moveCounterclockwise, .moveUp, .moveDown]
            return navigationItems + fileMenuItems
        case .auto:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .moveClockwise, .moveCounterclockwise]
            return navigationItems + fileMenuItems
        case .navigation:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .stopNavigation]
            return navigationItems + fileMenuItems
        }
    }

    /// All available MenubarItems items.
    fileprivate var allItems: [MenubarItem] {
        return NavigationMenubarItem.allCases + FileMenubarItem.allCases
    }
}

class MenubarController {
    public static var state: MenubarState = .disconnected {
        didSet {
            // Disable all items.
            self.state.allItems.forEach { $0.disable() }
            // Enable the items relevant for this state.
            self.state.enabledItems.forEach { $0.enable() }
        }
    }
}
