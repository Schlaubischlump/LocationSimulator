//
//  Device.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

/// Notifications when a device is connected / paired / disconnected.
public extension Notification.Name {
    /// Called when a new device is paired with this computer.
    static let DevicePaired = Notification.Name("iDevicePaired")
    /// Called when an existing device changes, e.g. a new connection type is added to a device.
    static let DeviceChanged = Notification.Name("iDeviceChanged")
    /// Called when a new device is connected.
    static let DeviceConnected = Notification.Name("iDeviceConntected")
    /// Called when a device is disconnected.
    static let DeviceDisconnected = Notification.Name("iDeviceDisconntected")
}

protocol Device: CustomStringConvertible {//: Hashable {//, CustomStringConvertible {
    /// Unique device ID (UDID) string.
    var udid: String { get }
    /// The device name e.g. John's iPhone
    var name: String { get }
    /// The connection type (USB, Network or Unknown)
    var connectionType: ConnectionType { get }
    /// True if we currently generate device notifications, false otherwise.
    static var isGeneratingDeviceNotifications: Bool { get }

    /// Start an observer for newly added, paired or removed devices.
    /// - Return: True if the observer could be started, false otherwise.
    @discardableResult
    static func startGeneratingDeviceNotifications() -> Bool
    /// Stop observing device changes.
    /// - Return: True if the observer could be closed, False otherwise.
    @discardableResult
    static func stopGeneratingDeviceNotifications() -> Bool
    /// Pair the specific device with this computer and try to upload the DeveloperDiskImage.
    func pair() throws
    /// Set the device location to the new coordinates.
    /// - Parameter location: new coordinates
    /// - Return: True on success, false otherwise.
    @discardableResult
    func simulateLocation(_ location: CLLocationCoordinate2D) -> Bool
    /// Stop spoofing the device location and reset the coordinates to the real device coordinates.
    /// - Return: True on success, False otherwise.
    @discardableResult
    func disableSimulation() -> Bool
}

extension Device {
    var description: String {
        return "\(type(of: self))(udid: \(self.udid), name: \(self.name), connectionType: \(self.connectionType))"
    }
}
