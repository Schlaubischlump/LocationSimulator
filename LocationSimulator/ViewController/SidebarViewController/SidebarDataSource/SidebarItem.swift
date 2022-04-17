//
//  SidebarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import LocationSpoofer

protocol SidebarItem {
    /// The TableViewCell text.
    var name: String { get }
    /// The TableViewCell image.
    var image: NSImage? { get }
    /// True if the TableViewCell a group item, false otherwise.
    var isGroupItem: Bool { get }
    /// The cell identifier string.
    var identifier: NSUserInterfaceItemIdentifier { get }
}

/// Support the Device type as sidebar item.
extension IOSDevice: SidebarItem {
    var image: NSImage? {
        return self.usesNetwork ? NSImage(named: "wifi") : NSImage(named: "usb")
    }

    var isGroupItem: Bool {
        return false
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "DeviceCell")
    }
}

extension SimulatorDevice: SidebarItem {
    var image: NSImage? {
        return NSImage(named: "Simulator")
    }

    var isGroupItem: Bool {
        return false
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "DeviceCell")
    }
}

/// The main Header table view cell, which contains all simulator devices.
struct SimDeviceHeader: SidebarItem {
    var name: String {
        return "SIMULATOR_HEADER".localized
    }

    var image: NSImage? {
        return nil
    }

    var isGroupItem: Bool {
        return true
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
    }
}

/// The main Header table view cell, which contains all devices.
struct IOSDeviceHeader: SidebarItem {
    var name: String {
        return "DEVICE_HEADER".localized
    }

    var image: NSImage? {
        return nil
    }

    var isGroupItem: Bool {
        return true
    }

    var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
    }
}
