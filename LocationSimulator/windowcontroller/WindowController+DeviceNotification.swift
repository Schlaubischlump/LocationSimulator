//
//  WindowController+DeviceNotification.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

extension WindowController {
    /**
     Callback when a device gets connected.
     - Parameter notification: notification with device information (UDID and name)
     */
    @objc func deviceConnected(_ notification: Notification) {
        guard let udid: String = notification.userInfo?["UDID"] as? String,
            let name: String = notification.userInfo?["NAME"] as? String else { return }

        // For some reason sometimes the same device should be added twice
        if self.deviceUDIDs.contains(udid) { return }

        // add the new device to the internal list and the UI
        self.deviceUDIDs.append(udid)
        self.devicesPopup.addItem(withTitle: name)

        // first device connected => automatically pair it
        if self.deviceUDIDs.count == 1, let viewController = self.contentViewController as? MapViewController {
            if viewController.loadDevice(udid) {
                viewController.spoofer!.moveType = MoveType(rawValue: self.typeSegmented.selectedSegment) ?? .walk
                // make sure to enable the menubar item
                NavigationMenubarItem.setLocation.enable()
                NavigationMenubarItem.recentLocation.enable()
            }
        }
    }

    /**
     Callback when a device gets paired for the first time with this computer. We could restart the device creation
     process here... For now we just asume the device is already paired and trusted.
     - Parameter notification: notification with device information (UDID and name)
     */
    @objc func devicePaired(_ notification: Notification) {
        guard let udid: String = notification.userInfo?["UDID"] as? String,
            let name: String = notification.userInfo?["NAME"] as? String else { return }
        print("[INFO]: Paired device: \(name) with UDID: \(udid)")
    }

    /**
     Callback when a device gets disconnected.
     - Parameter notification: notification with device information (UDID)
     */
    @objc func deviceDisconnected(_ notification: Notification) {
        guard let udid: String = notification.userInfo?["UDID"] as? String,
            let viewController = contentViewController as? MapViewController else { return }

        // remove the device from the list and the list popup
        if let index: Int = self.deviceUDIDs.firstIndex(of: udid) {
            let removedCurrentDevice = (self.devicesPopup.indexOfSelectedItem == index)
            self.devicesPopup.removeItem(at: index)
            self.deviceUDIDs.remove(at: index)
            // remove the last known location for this device
            self.lastKnownLocationCache.removeValue(forKey: udid)

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
            if removedCurrentDevice, self.devicesPopup.numberOfItems > 0 {
                self.deviceSelected(self.devicesPopup)
            }
        }
    }
}
