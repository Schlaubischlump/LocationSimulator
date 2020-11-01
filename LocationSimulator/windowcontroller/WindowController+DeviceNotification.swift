//
//  WindowController+DeviceNotification.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

let kUSBIconImage: NSImage? = NSImage(named: "usb")
let kWIFIIconImage: NSImage? = NSImage(named: "wifi")

extension WindowController {

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

        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices

        // add the new device to the internal list and update the UI
        self.devices.append(device)
        self.devicesPopup.addItem(withTitle: device.name)
        self.devicesPopup.lastItem?.image = (device.usesNetwork ? kWIFIIconImage : kUSBIconImage)
        self.devicesPopup.lastItem?.image?.size = CGSize(width: 20, height: 20)

        // first device connected => automatically pair it
        if self.devices.count == 1, let viewController = self.contentViewController as? MapViewController {
            if viewController.load(device: device) {
                viewController.spoofer!.moveType = MoveType(rawValue: self.typeSegmented.selectedSegment) ?? .walk
                // make sure to enable the menubar item
                NavigationMenubarItem.setLocation.enable()
                NavigationMenubarItem.recentLocation.enable()
            }
        }
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
        guard var device: Device = notification.userInfo?["device"] as? Device,
              let viewController = contentViewController as? MapViewController else { return }

        // the internal `preferNetworkConnection` might not be updated for the cached device
        device.preferNetworkConnection = UserDefaults.standard.preferNetworkDevices

        // Device is a struct. We therefore need to update the existing struct to write the changes.
        if let index: Int = self.devices.firstIndex(of: device) {
            self.devices[index] = device

            // update the device popup
            self.devicesPopup.item(at: index)?.image = (device.usesNetwork ? kWIFIIconImage : kUSBIconImage)
            self.devicesPopup.item(at: index)?.image?.size = CGSize(width: 20, height: 20)

            print("[INFO]: Update device: \(device.name) with UDID: \(device.udid)")
        }

        // sometimes the mapView looses focus when connecting and disconnecting a device
        viewController.becomeFirstResponder()
    }

    /// Callback when a device gets disconnected.
    /// - Parameter notification: notification with device information (UDID)
    @objc func deviceDisconnected(_ notification: Notification) {
        guard let device: Device = notification.userInfo?["device"] as? Device,
              let viewController = contentViewController as? MapViewController else { return }

        // remove the device from the list and the list popup
        if let index: Int = self.devices.firstIndex(of: device) {
            print("[INFO]: Disconnect device: \(device.name) with UDID: \(device.udid)")

            let removedCurrentDevice = (self.devicesPopup.indexOfSelectedItem == index)
            self.devicesPopup.removeItem(at: index)
            self.devices.remove(at: index)
            // remove the last known location for this device
            self.lastKnownLocationCache.removeValue(forKey: device)

            // if the current device was removed, reset the UI
            if removedCurrentDevice {
                if let spoofer = viewController.spoofer {
                    // disable all events
                    spoofer.moveState = .manual
                    spoofer.delegate = nil

                    // make sure the GUI is reset
                    viewController.willChangeLocation(spoofer: spoofer, toCoordinate: nil)
                    viewController.didChangeLocation(spoofer: spoofer, toCoordinate: nil)
                }

                // cleanup the spoofer instance for the device
                viewController.spoofer = nil
                // reset the total distance label
                let emptyTotalDistanceString = String(format: NSLocalizedString("TOTAL_DISTANCE", comment: ""), 0)
                viewController.totalDistanceLabel.stringValue = emptyTotalDistanceString

                // disable the menubar items
                let items: [NavigationMenubarItem] = [.setLocation, .toggleAutomove, .moveUp, .moveDown,
                                                      .moveCounterclockwise, .moveClockwise, .stopNavigation,
                                                      .recentLocation]
                items.forEach { item in item.disable() }

                // try to select the next device in the list
                if self.devicesPopup.numberOfItems > 0 {
                    self.deviceSelected(self.devicesPopup)
                }
            }
        }
    }
}
