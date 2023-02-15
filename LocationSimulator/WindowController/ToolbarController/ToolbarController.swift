//
//  ToolbarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 24.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit
import SuggestionPopup
import LocationSpoofer

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

    /// The search completer instance to handle the search and displaying the results.
    var searchCompleter: LocationSearchCompleter!

    // MARK: - ToolbarItem views

    @IBOutlet weak var autofocusButton: NSButton!

    @IBOutlet weak var autoreverseButton: NSButton!

    @IBOutlet weak var currentLocationButton: NSButton!

    @IBOutlet weak var resetLocationButton: NSButton!

    @IBOutlet weak var speedSlider: ValueTrackingSlider! {
        didSet {
            self.speedSlider.minValue = 0
            self.speedSlider.maxValue = kSpeedSliderMaxExponent

            self.speedSlider.formatHandler = { value in
                let speedInKmH = pow(kSpeedSliderLogBase, value)
                return "\(round(speedInKmH * 10)/10) km/h"
            }
        }
    }

    @IBOutlet weak var searchField: NSSearchField! {
        didSet {
            self.searchCompleter = LocationSearchCompleter(searchField: self.searchField)

            // Listen for the searchField first responder status to update the search status.
            self.searchCompleter.onSelect = { [weak self] text, suggestion in
                self?.windowController?.searchBarOnSelect(text: text, suggestion: suggestion)
            }
            self.searchCompleter.onBecomeFirstReponder = { [weak self] in
                self?.windowController?.searchBarOnBecomeFirstReponder()
            }
            self.searchCompleter.onResignFirstReponder = { [weak self] in
                self?.windowController?.searchBarOnBecomeFirstReponder()
            }
        }
    }

    @IBOutlet weak var moveTypeSegment: NSSegmentedControl!

    // MARK: - ToolbarItems

    @IBOutlet weak var autofocusItem: NSToolbarItem!

    @IBOutlet weak var autoreverseItem: NSToolbarItem!

    @IBOutlet weak var currentLocationItem: NSToolbarItem!

    @IBOutlet weak var resetLocationItem: NSToolbarItem!

    @IBOutlet weak var searchFieldItem: NSToolbarItem!

    @IBOutlet weak var moveTypeSegmentItem: NSToolbarItem!

    @IBOutlet weak var speedSliderItem: NSToolbarItem!

    // MARK: - Constructor

    private func setup() {
        self.registerNotifications()
    }

    override init() {
        super.init()
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - Helper

    /// The current speed value in meters per second.
    public var speed: CLLocationSpeed {
        get {
            let speedInKmH = pow(kSpeedSliderLogBase, self.speedSlider.doubleValue)
            return CLLocationSpeed(inKmH: speedInKmH)
        }
        set {
            self.speedSlider.doubleValue = log(newValue.inKmH)/log(kSpeedSliderLogBase)
        }
    }

    /// Get or set the currently selected moveType.
    public var moveType: MoveType {
        get {
            return MoveType(rawValue: self.moveTypeSegment.selectedSegment)!
        }
        set {
            self.moveTypeSegment.selectedSegment = newValue.rawValue

            // Change the currently displayed speed value to the default speed for this move type
            let speedInKmH = newValue.speed * 3.6
            self.speedSlider.doubleValue = log(speedInKmH)/log(kSpeedSliderLogBase)
        }
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
        let deviceConnected = (deviceStatus == .connected)
        let deviceDisconnected = (deviceStatus == .disconnected)
        let hasSpoofedLocation = (deviceStatus == .manual || deviceStatus == .auto || deviceStatus == .navigation)
        self.autofocusItem.isEnabled = !deviceDisconnected
        self.autoreverseItem.isEnabled = deviceStatus == .navigation
        self.currentLocationItem.isEnabled = !deviceDisconnected
        self.searchFieldItem.isEnabled = !deviceDisconnected
        self.resetLocationItem.isEnabled = hasSpoofedLocation
        self.moveTypeSegmentItem.isEnabled = true
        // Clear the searchField.
        if deviceDisconnected || deviceConnected {
            self.searchField.stringValue = ""
        }
    }

    // MARK: - Toolbar Actions

    /// Toggle the autofocus status
    /// - Parameter sender: the button which triggered the action
    @IBAction func autofocusLocationClicked(_ sender: NSButton) {
        self.windowController?.setAutofocusEnabled(sender.state == .on)
    }

    /// Toggle the autoreverse status to repeat the currently navigated route.
    /// - Parameter sender: the button which triggered the action
    @IBAction func autoreverseClicked(_ sender: NSButton) {
        self.windowController?.setAutoreverseEnabled(sender.state == .on)
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
    /// - Parameter sender: the segmented control instance inside the toolbar.
    @IBAction func moveTypeSegmentChanged(_ sender: NSSegmentedControl) {
        guard let moveType = MoveType(rawValue: sender.selectedSegment) else { return }
        self.windowController?.setMoveType(moveType)
    }

    /// Callback when the speed slider is moved.
    /// - Parameter sender: slider inside the toolbar
    @IBAction func speedValueChanged(_ sender: NSSlider) {
        // Calculate a logarithmic speed value
        let speedInKmH = pow(kSpeedSliderLogBase, sender.doubleValue)
        let speedInMS = (speedInKmH * 1000)/(60*60)

        self.windowController?.setSpeed(speedInMS)
    }

    /// Toggle the visibility of the sidebar.
    /// - Parameter sender: the button which triggered the action
    @IBAction func toggleSidebar(_ sender: NSButton) {
        self.windowController?.toggleSidebar()
    }

}
