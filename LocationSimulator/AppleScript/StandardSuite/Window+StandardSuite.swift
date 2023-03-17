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
import LocationSpoofer

public enum ASMapType: UInt32 {
    case explore  = 0x4C736578 // Lsex
    case satellite = 0x4C737361 // Lssa
    case hybrid = 0x4C736879 // Lshy

    init(mkMapType: MKMapType) {
        switch mkMapType {
        case .standard, .mutedStandard:      self = .explore
        case .satellite, .satelliteFlyover:  self = .satellite
        case .hybrid, .hybridFlyover:        self = .hybrid
        @unknown default: self = .explore
        }
    }

    var mkMapType: MKMapType {
        switch self {
        case .explore:   return .standard
        case .satellite: return .satellite
        case .hybrid:    return .hybrid
        }
    }
}

extension ASTransportType {
    init(moveType: MoveType) {
        switch moveType {
        case .walk:  self = .walk
        case .cycle: self = .cycle
        case .drive: self = .drive
        }
    }

    var moveType: MoveType {
        switch self {
        case .walk:  return .walk
        case .cycle: return .cycle
        case .drive: return .drive
        }
    }
}

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

    @objc private var sidebarIsCollapsed: Bool {
        get {
            let splitViewController = (self.windowController as? WindowController)?.splitViewController
            return splitViewController?.isSidebarCollapsed ?? true
        }
        set {
            guard let splitViewController = (self.windowController as? WindowController)?.splitViewController else {
                return
            }
            if splitViewController.isSidebarCollapsed != newValue {
                splitViewController.toggleSidebar()
            }
        }
    }

    @objc var moveType: UInt32 {
        get {
            if let moveType = (self.windowController as? WindowController)?.moveType {
                return ASTransportType(moveType: moveType).rawValue
            }
            return ASTransportType.walk.rawValue
        }
        set {
            let transortType = ASTransportType(rawValue: newValue) ?? .walk
            (self.windowController as? WindowController)?.setMoveType(transortType.moveType)
        }
    }

    @objc var mapType: UInt32 {
        get {
            if let mapType = (self.windowController as? WindowController)?.mapType {
                return ASMapType(mkMapType: mapType).rawValue
            }
            return ASMapType.explore.rawValue
        }
        set {
            let mapType = ASMapType(rawValue: newValue) ?? .explore
            (self.windowController as? WindowController)?.setMapType(mapType.mkMapType)
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
