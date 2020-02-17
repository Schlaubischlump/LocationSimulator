//
//  WindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import MapKit

class WindowController: NSWindowController {
    /// Enable, disable autofocus current location.
    @IBOutlet weak var currentLocationButton: NSButton!

    /// Change the current move speed.
    @IBOutlet weak var typeSegmented: NSSegmentedControl!

    /// Search for a location inside the map.
    @IBOutlet weak var searchField: LocationSearchField!

    /// Change the current device.
    @IBOutlet weak var devicesPopup: NSPopUpButton!

    /// Search completer to find a location based on a string.
    public var searchCompleter: MKLocalSearchCompleter!

    /// UDIDs of all currently connected devices.
    public var deviceUDIDs: [String]!

    // MARK: - Window lifecycle

    override func windowDidLoad() {
        super.windowDidLoad()

        // save the UDIDs of all connected devices
        self.deviceUDIDs = []

        if Device.startGeneratingDeviceNotifications() {
            NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnected), name: .DeviceConnected, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.devicePaired), name: .DevicePaired, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDisconnected), name: .DeviceDisconnected, object: nil)
        }

        // setup the location searchfield
        searchField.tableViewDelegate = self

        // only search for locations
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.filterType = .locationsOnly

        // listen to current location changes
        NotificationCenter.default.addObserver(forName: .AutoFoucusCurrentLocationChanged, object: nil, queue: .main) { (notification) in
            if let isOn = notification.object as? Bool, isOn == true {
                self.currentLocationButton.state = .on
            } else {
                self.currentLocationButton.state = .off
            }
        }
    }

    deinit {
        // stop generating update notifications (0 != 1 can never occur)
        Device.stopGeneratingDeviceNotifications()

        // remove all notifications
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Interface Builder callbacks

    @IBAction func currentLocationClicked(_ sender: NSButton) {
        guard let viewController = contentViewController as? MapViewController else { return }

        if viewController.currentLocationMarker == nil {
            sender.state = .off
        } else {
            viewController.autoFocusCurrentLocation = (sender.state == .on)
        }
    }
    
    @IBAction func typeSegmentChanged(_ sender: NSSegmentedControl) {
        guard let viewController = contentViewController as? MapViewController else { return }
        viewController.spoofer?.moveType = MoveType(rawValue: sender.selectedSegment)!
    }
    
    @IBAction func resetClicked(_ sender: NSButton) {
        guard let viewController = contentViewController as? MapViewController else { return }
        viewController.spoofer?.resetLocation()
    }

    @IBAction func deviceSelected(_ sender: NSPopUpButton) {
        // Disable all menubar items which only work if a device is connected.
        let items: [MenubarItem] = [.SetLocation,.ToggleAutomove, .MoveUp, .MoveDown, .MoveCounterclockwise,
                                    .MoveClockwise]
        items.forEach { item in item.disable() }

        guard let viewController = contentViewController as? MapViewController else { return }

        let index: Int = sender.indexOfSelectedItem
        let udid: String = self.deviceUDIDs[index]

        // cleanup the UI if a previous device was selected
        if let spoofer = viewController.spoofer {
            // if the selection did not change do nothing
            if spoofer.device.UDID == udid {
                MenubarItem.SetLocation.enable()
                return
            }
            // reset the timer and cancel all delegate updates
            spoofer.moveState = .manual
            spoofer.delegate = nil

            // explicitly force the UI to reset
            viewController.willChangeLocation(spoofer: spoofer, toCoordinate: nil)
            viewController.didChangeLocation(spoofer: spoofer, toCoordinate: nil)
        }

        // load the new device
        if viewController.loadDevice(udid) {
            // set the correct walking speed based on the current selection
            viewController.spoofer!.moveType = MoveType(rawValue: self.typeSegmented.selectedSegment) ?? .walk
            // make sure to enable the 'Set Location' menubar item if a device is connected
            MenubarItem.SetLocation.enable()
        }
    }
}


