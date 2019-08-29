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

let kLeftKey: UInt16 = 123
let kRightKey: UInt16 = 124
let kDownKey: UInt16 = 125
let kUpKey: UInt16 = 126
let kSpaceKey: UInt16 = 49
let kWKey: UInt16 = 13
let kCKey: UInt16 = 8
let kDKey: UInt16 = 2


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

    /// Event monitor to responds to keyboard events.
    private var localKeyEventMonitor: Any?

    /// True if we currently listen to connected / disconnected device notifcation, False otherwise.
    private var observeDevices: Bool!

    // MARK: - Window lifecycle

    override func windowDidLoad() {
        super.windowDidLoad()

        // save the UDIDs of all connected devices
        self.deviceUDIDs = []

        // start listening to new devices if possible
        self.observeDevices = Device.startGeneratingDeviceNotifications()

        if self.observeDevices {
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

        self.localKeyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown])
        { [unowned self] (event) -> NSEvent? in
            // only handle events if the mapview is the first responder
            guard let viewController = self.contentViewController as? MapViewController,
                  let view = self.window?.firstResponder, view == viewController.mapView,
                  let spoofer = viewController.spoofer else { return event }

            // The locaiton is not spoofed yet => use default behaviour
            if viewController.currentLocationMarker == nil {
                return event
            }

            // allow manual moving with the arrow keys
            switch event.keyCode {
            case kWKey:
                self.typeSegmented.selectedSegment = 0
                self.typeSegmentChanged(self.typeSegmented)
                return nil
            case kCKey:
                self.typeSegmented.selectedSegment = 1
                self.typeSegmentChanged(self.typeSegmented)
                return nil
            case kDKey:
                self.typeSegmented.selectedSegment = 2
                self.typeSegmentChanged(self.typeSegmented)
                return nil
            case kLeftKey:
                viewController.rotateHeaderViewBy(CGFloat(5.0.degreesToRadians))
                return nil
            case kRightKey:
                viewController.rotateHeaderViewBy(CGFloat(-5.0.degreesToRadians))
                return nil
            case kDownKey:
                //  x | x                 |          |                   |
                // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
                //    |    arrow down   x | x      x | x  arrow down   x | x
                if spoofer.moveState == .manual {
                    let angle = viewController.getHeaderViewAngle()
                    if (angle < .pi/2.0 && angle > -.pi/2.0) {
                        viewController.rotateHeaderViewBy(.pi)
                    }
                    spoofer.move()
                }
                return nil
            case kUpKey:
                //    |                 x | x      x | x               x | x
                // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
                //  x | x   arrow up      |          |     arrow up      |
                if spoofer.moveState == .manual {
                    let angle = viewController.getHeaderViewAngle()
                    if (angle > .pi/2.0 || angle < -.pi/2.0) {
                        viewController.rotateHeaderViewBy(.pi)
                    }
                    spoofer.move()
                }
                return nil
            case kSpaceKey:
                // pause navigation
                spoofer.pauseResumeNavigationAutoMove()
                return nil
            default:
                break
            }

            return event
        }
    }

    deinit {
        // stop generating update notifications (0 != 1 can never occur)
        self.observeDevices = self.observeDevices != Device.stopGeneratingDeviceNotifications()

        // remove all notifications
        NotificationCenter.default.removeObserver(self)

        // stop listening for keyboard events
        if let eventMonitor = self.localKeyEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.localKeyEventMonitor = nil
        }
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
        guard let viewController = contentViewController as? MapViewController else { return }

        let index: Int = sender.indexOfSelectedItem
        let udid: String = self.deviceUDIDs[index]

        // cleanup the UI if a previous device was selected
        if let spoofer = viewController.spoofer {
            // if the selection did not change do nothing
            if spoofer.device.UDID == udid {
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
        }
    }
}


