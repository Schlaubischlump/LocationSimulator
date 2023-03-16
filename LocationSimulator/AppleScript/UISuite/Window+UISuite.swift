//
//  Window+UISuite.swift
//  LocationSimulator
//
//  Created by David Klopp on 16.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CoreLocation

extension Window {
    @objc private var mapViewController: MapViewController? {
        (self.windowController as? WindowController)?.mapViewController
    }

    @objc private var selectedDevice: ASDevice? {
        get {
            if let map = self.mapViewController {
                return ASDevice(device: map.device!)
            }
            return nil
        }
        set {
            let splitViewController = (self.windowController as? WindowController)?.splitViewController
            if let device = newValue?.device {
                splitViewController?.sidebarViewController?.select(device: device)
            }

        }
    }

    @objc private var speed: CLLocationSpeed {
        get { return (self.windowController as? WindowController)?.speed.inKmH ?? -1 }
        set {
            let speed = CLLocationSpeed(inKmH: max(kMinSpeed, min(newValue, kMaxSpeed)))
            let windowController = self.windowController as? WindowController
            windowController?.setSpeed(speed)
            windowController?.toolbarController.speed = speed
        }
    }

    @objc(clearDeviceSelection:) private func clearDeviceSelection(_ command: NSScriptCommand) {
        let splitViewController = (self.windowController as? WindowController)?.splitViewController
        splitViewController?.sidebarViewController?.select(device: nil)
    }

}
