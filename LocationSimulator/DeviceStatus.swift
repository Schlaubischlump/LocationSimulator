//
//  AppState.swift
//  LocationSimulator
//
//  Created by David Klopp on 24.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

/// An enum that defines which UI elements should be active give a specific device status.
enum DeviceStatus {
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
    public var enabledMenubarItems: [MenubarItem] {
        var navigationItems: [NavigationMenubarItem] = [.walk, .cycle, .drive]
        let fileMenuItems: [FileMenubarItem] = [.openGPXFile]
        var viewMenuItems: [ViewMenubarItem] = [.toggleSidebar, .explore, .hybrid, .satellite]

        switch self {
        case .disconnected:
            return navigationItems
        case .connected:
            navigationItems += [.setLocation, .recentLocation, .useMacLocation]
            viewMenuItems += [.zoomIn, .zoomOut]
            return navigationItems + fileMenuItems + viewMenuItems
        case .manual:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .moveRight, .moveLeft, .moveUp, .moveDown]
            viewMenuItems += [.zoomIn, .zoomOut]
            return navigationItems + fileMenuItems + viewMenuItems
        case .auto:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .moveRight, .moveLeft]
            viewMenuItems += [.zoomIn, .zoomOut]
            return navigationItems + fileMenuItems + viewMenuItems
        case .navigation:
            navigationItems += [.setLocation, .recentLocation, .resetLocation, .useMacLocation, .toggleAutomove,
                                .stopNavigation]
            viewMenuItems += [.zoomIn, .zoomOut]
            return navigationItems + fileMenuItems + viewMenuItems
        }
    }

    /// All available MenubarItems items.
    public var allMenubarItems: [MenubarItem] {
        return NavigationMenubarItem.allCases + FileMenubarItem.allCases + ViewMenubarItem.allCases
    }
}
