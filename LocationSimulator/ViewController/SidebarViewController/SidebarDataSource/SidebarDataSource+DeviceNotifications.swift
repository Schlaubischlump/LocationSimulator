//
//  SidebarDataSource+DeviceNotifications.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

extension SidebarDataSource {

    /// Register all notification handler.
    public func registerDeviceNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnected),
                                               name: .DeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceChanged),
                                               name: .DeviceChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.devicePaired),
                                               name: .DevicePaired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDisconnected),
                                               name: .DeviceDisconnected, object: nil)
    }

    /// Callback when a device gets connected.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func deviceConnected(_ notification: Notification) {
        guard var device: Device = notification.userInfo?["device"] as? Device else { return }

        // This should never be the case, but let's make sure that a device is unique.
        if self.devices.contains(device) { return }

        print("[INFO]: Connect device: \(device.name) with UDID: \(device.udid)")

        // The internal `preferNetworkConnection` might not be updated for the cached device
        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices

        // Insert the device alphabetically at the correct index.
        let index = self.devices.insertionIndexOf(device) { $0.name < $1.name }

        // Add the new device to the internal list and update the UI
        self.devices.insert(device, at: index)

        // index +1 for the HeaderCell
        self.sidebarView?.insertItems(at: [index+1], inParent: nil, withAnimation: .effectGap)

        // If no device is selected, select the first.
        /*if let rowCount = self.sidebarView?.numberOfSelectedRows, rowCount == 0 {
            // Index 1, because we don't want to select the header.
            self.sidebarView?.selectRowIndexes([1], byExtendingSelection: false)
        }*/
    }

    /// Callback when a device gets paired for the first time with this computer. We could restart the device creation
    /// process here... For now we just asume the device is already paired and trusted.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func devicePaired(_ notification: Notification) {
        guard let device: Device = notification.userInfo?["device"] as? Device else { return }
        print("[INFO]: Paired device: \(device.name) with UDID: \(device.udid)")
    }

    /// Callback when a device is changed. This might happen if a network device is additionally connected over USB.
    /// - Parameter notification: notification with device information (UDID and name)
    @objc func deviceChanged(_ notification: Notification) {
        guard var device: Device = notification.userInfo?["device"] as? Device else { return }

        // the internal `preferNetworkConnection` might not be updated for the cached device
        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices

        // Device is a struct. We therefore need to update the existing struct to write the changes.
        if let index: Int = self.devices.firstIndex(of: device) {
            self.devices[index] = device

            print("[INFO]: Update device: \(device.name) with UDID: \(device.udid)")

            // Update the image and the text. index+1 for the HeaderCell
            self.updateCell(atIndex: index+1)
        }
    }

    /// Callback when a device gets disconnected.
    /// - Parameter notification: notification with device information (UDID)
    @objc func deviceDisconnected(_ notification: Notification) {
        guard let device: Device = notification.userInfo?["device"] as? Device else { return }

        // remove the device from the list and the list popup
        if let index: Int = self.devices.firstIndex(of: device) {
            print("[INFO]: Disconnect device: \(device.name) with UDID: \(device.udid)")

            // True if the currently selected device was removed.
            let removeCurrent = (self.selectedDevice == self.devices.remove(at: index))

            // If the current device was removed, we need to change the status to disconnect.
            // We do this by removing the device instance.
            if removeCurrent {
                let windowController = self.sidebarView?.window?.windowController as? WindowController
                windowController?.mapViewController?.device = nil
            }

            // index +1 for the HeaderCell
            self.sidebarView?.removeItems(at: [index+1], inParent: nil, withAnimation: .effectGap)
        }
    }
}
