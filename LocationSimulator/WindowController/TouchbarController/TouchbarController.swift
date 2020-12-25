//
//  TouchbarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class TouchbarController: NSResponder {
    /// The corresponding windowController for this toolbar controller.
    @IBOutlet weak var windowController: WindowController?

    /// A reference to the current mapViewController if available.
    private var mapViewController: MapViewController? {
        return self.windowController?.mapViewController
    }

    // MARK: - TouchbarItem Views

    @IBOutlet weak var moveTypeSegment: NSSegmentedControl!

    // MARK: - TouchbarItems

    @IBOutlet weak var moveTypeSegmentItem: NSTouchBarItem!

    @IBOutlet weak var currentLocationItem: NSTouchBarItem!

    @IBOutlet weak var resetLocationItem: NSTouchBarItem!

    // MARK: - Helper

    public var moveType: MoveType {
        get { return MoveType(rawValue: self.moveTypeSegment.selectedSegment)! }
        set { self.moveTypeSegment.selectedSegment = newValue.rawValue }
    }

    // MARK: - Notification

    /// Listen for state changes
    public func updateForDeviceStatus(_ deviceStatus: DeviceStatus) {
        let deviceDisconnected = deviceStatus == .disconnected
        self.currentLocationItem.isEnabled = !deviceDisconnected
        let hasSpoofedLocation = (deviceStatus == .manual || deviceStatus == .auto || deviceStatus == .navigation)
        self.resetLocationItem.isEnabled = hasSpoofedLocation
        self.moveTypeSegmentItem.isEnabled = true
    }

    // MARK: - Touchbar Actions

    /// Set the current location to the mac's location.
    /// - Parameter sender: the button which triggered the action
    @IBAction func currentLocationClicked(_ sender: NSButton) {
        self.windowController?.setLocationToCurrentLocation()
    }

    /// Stop spoofing the current location.
    /// - Parameter sender: the button which triggered the action
    @IBAction func resetLocationClicked(_ sender: NSButton) {
        self.windowController?.resetLocation()
    }

    /// Change the move speed to walk / cycle / drive based on the selected segment.
    /// - Parameter sender: the segmented control instance inside the tool- or touchbar.
    @IBAction func moveTypeSegmentChanged(_ sender: NSSegmentedControl) {
        self.windowController?.setMoveType(MoveType(rawValue: sender.selectedSegment)!)
    }
}
