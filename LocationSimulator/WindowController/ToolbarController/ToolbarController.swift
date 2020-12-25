//
//  ToolbarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 24.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class ToolbarController: NSResponder {
    /// The corresponding windowController for this toolbar controller.
    @IBOutlet weak var windowController: WindowController?

    /// A reference to the current mapViewController if available.
    private var mapViewController: MapViewController? {
        return self.windowController?.mapViewController
    }

    // MARK: - Observer

    /// The notification observer for autofocus changes.
    private var autofocusObserver: NSObjectProtocol?

    // MARK: - ToolbarItem views

    @IBOutlet weak var autofocusButton: NSButton!

    @IBOutlet weak var currentLocationButton: NSButton!

    @IBOutlet weak var resetLocationButton: NSButton!

    @IBOutlet weak var searchField: NSSearchField!

    @IBOutlet weak var moveTypeSegment: NSSegmentedControl!

    // MARK: - ToolbarItems

    @IBOutlet weak var autofocusItem: NSToolbarItem!

    @IBOutlet weak var currentLocationItem: NSToolbarItem!

    @IBOutlet weak var resetLocationItem: NSToolbarItem!

    @IBOutlet weak var searchFieldItem: NSToolbarItem!

    @IBOutlet weak var moveTypeSegmentItem: NSToolbarItem!

    // MARK: - Constructor

    override init() {
        super.init()
        self.registerNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerNotifications()
    }

    // MARK: - Helper

    /// Get or set the currently selected moveType.
    public var moveType: MoveType {
        get { return MoveType(rawValue: self.moveTypeSegment.selectedSegment)! }
        set { self.moveTypeSegment.selectedSegment = newValue.rawValue }
    }

    // MARK: - Notification

    /// Listen for autofocus. changes
    private func registerNotifications() {
        self.autofocusObserver = NotificationCenter.default.addObserver(forName: .AutoFocusChanged, object: nil,
                                                    queue: .main) { [weak self] notification in
            guard notification.object as? MapViewController == self?.mapViewController else { return }
            guard let isOn = notification.userInfo?["autofocus"] as? Bool else { return }
            self?.autofocusButton.state =  isOn ? .on : .off
        }
    }

    deinit {
        // Remove the observer
        if let observer = self.autofocusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.autofocusObserver = nil
    }

    // MARK: - Helper

    public func updateForDeviceStatus(_ deviceStatus: DeviceStatus) {
        // Update the enabled status for each toolbar item.
        let deviceDisconnected = (deviceStatus == .disconnected)
        let hasSpoofedLocation = (deviceStatus == .manual || deviceStatus == .auto || deviceStatus == .navigation)
        self.autofocusItem.isEnabled = !deviceDisconnected
        self.currentLocationItem.isEnabled = !deviceDisconnected
        self.searchFieldItem.isEnabled = !deviceDisconnected
        self.resetLocationItem.isEnabled = hasSpoofedLocation
        self.moveTypeSegmentItem.isEnabled = true
    }

    // MARK: - Toolbar Actions

    /// Toggle the autofocus status
    /// - Parameter sender: the button which triggered the action
    @IBAction func autofocusLocationClicked(_ sender: NSButton) {
        self.windowController?.setAutofocusEnabled(sender.state == .on)
    }

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
