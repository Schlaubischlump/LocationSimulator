//
//  ASDevice.swift
//  LocationSimulator
//
//  Created by David Klopp on 05.05.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit
import Foundation
import CoreLocation
import LocationSpoofer

/// A wrapper around the device protocol for apple script interaction.
@objc(ASDevice) class ASDevice: NSObject {
    internal var device: Device

    // MARK: - Properties

    @objc public var uuid: String {
        return self.device.udid
    }

    @objc public var name: String {
        return self.device.name
    }

    @objc public var productVersion: String? {
        return self.device.version
    }

    @objc public var productName: String? {
        return self.device.productName
    }

    @objc public var isSimulator: Bool {
        if self.device as? SimulatorDevice != nil {
            return true
        }
        return false
    }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let appDescription = NSApp.classDescription as? NSScriptClassDescription else { return nil }
        return NSUniqueIDSpecifier(containerClassDescription: appDescription, containerSpecifier: nil, key: "devices",
                                   uniqueID: self.uuid)
    }

    static var availableDevices: [ASDevice] {
        return (IOSDevice.availableDevices + SimulatorDevice.availableDevices).map { ASDevice(device: $0) }
    }

    internal init(device: Device) {
        self.device = device
    }

    // MARK: - Change location

    @objc(changeLocation:) private func changeLocation(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
              let latitude = params["latitude"] as? CGFloat, let longitude = params["longitude"] as? CGFloat else {
            return false
        }
        return self.device.simulateLocation(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }

    @objc(resetLocation:) private func resetLocation(_ command: NSScriptCommand) -> Any? {
        return self.device.disableSimulation()
    }

    // MARK: - Upload DeveloperDiskImage

    @objc(pair:) private func pair(_ command: NSScriptCommand) {
        do {
            try self.device.pair()
        } catch let error {
            command.setScriptError(error)
        }
    }
}
