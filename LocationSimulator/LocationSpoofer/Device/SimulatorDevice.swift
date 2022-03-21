//
//  SimulatorDevice.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import CLogger

struct SimulatorDevice: Device {
    /// Unique Device ID (UDID) string.
    public internal(set) var udid: String = ""
    /// The device name e.g. John's iPhone
    public internal(set) var name: String = ""
    /// The connection type (USB, Network or Unknown)
    public internal(set) var connectionType: ConnectionType = .unknown
    /// Internal wrapper around the simulator device
    private var wrapper: SimDeviceWrapper?

    /// Are we currently generating simulator device notifications.
    public static var isGeneratingDeviceNotifications: Bool {
        return SimulatorDevice.subscriberID != nil
    }

    /// The internal handler id for simulator device notifications
    static private var subscriberID: UInt?

    @discardableResult
    static func startGeneratingDeviceNotifications() -> Bool {
        guard !SimulatorDevice.isGeneratingDeviceNotifications else { return false }

        // Listen for new simulator devices.
        SimulatorDevice.subscriberID = SimDeviceWrapper.subscribe { simDeviceWrapper in
            let udid = simDeviceWrapper.udid()
            let name = simDeviceWrapper.name()
            let device = SimulatorDevice(udid: udid, name: name, connectionType: .unknown, wrapper: simDeviceWrapper)
            let connected =  simDeviceWrapper.isConnected()
            let notification: Notification.Name = connected ? .DeviceConnected : .DeviceDisconnected
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: notification, object: nil, userInfo: ["device": device])
            }
        }

        return true
    }

    @discardableResult
    static func stopGeneratingDeviceNotifications() -> Bool {
        guard SimulatorDevice.isGeneratingDeviceNotifications else { return false }
        // TODO: Remove known devices. Since this is only called when the app is closed, this is not relevant
        return SimDeviceWrapper.unsubscribe(SimulatorDevice.subscriberID!)
    }

    func pair() throws {
        // Nothing to do here
    }

    func simulateLocation(_ location: CLLocationCoordinate2D) -> Bool {
        return self.wrapper?.setLocationWithLatitude(location.latitude, andLongitude: location.longitude) ?? false
    }

    func disableSimulation() -> Bool {
        if self.wrapper?.resetLocation() ?? false {
            return true
        }
        logError("SimulatorDevice \"\(self.udid)\" - \(self.name): Could not reset location.")
        return false
    }
}

extension SimulatorDevice: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.udid == rhs.udid
    }
}
