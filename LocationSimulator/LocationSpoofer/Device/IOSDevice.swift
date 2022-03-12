//
//  Device.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

/// An internal map with all currently detected devices.
private var deviceList: [String: IOSDevice] = [:]

struct IOSDevice: Device {
    // MARK: - Static attributes

    /// The default `preferNetworkConnection` value.
    /// Change this value to change the `preferNetworkConnection` on initialisation for all devices.
    public static var preferNetworkConnectionDefault: Bool = false
    /// Set this value to true to find network & USB devices or to false to only find USB devices.
    public static var detectNetworkDevices: Bool = true
    /// True if we currently generate device notifications, false otherwise.
    public internal(set) static var isGeneratingDeviceNotifications: Bool = false
    /// Unique device ID (UDID) string.
    public internal(set) var udid: String = ""
    /// The device name e.g. John's iPhone
    public internal(set) var name: String = ""
    /// The connection type (USB, Network or Unknown)
    public internal(set) var connectionType: ConnectionType = .unknown

    // MARK: - Instance attributes

    /// Prefer the network connection even if the device is paired via USB.
    public var preferNetworkConnection: Bool = false
    /// Readonly: Get the current lookup flags to perform the request. This allows changing from USB to network.
    public var lookupOps: idevice_options {
        // Get the current lookup operations for this connection type. This might be USB, network or both.
        var ops = self.connectionType.lookupOps
        // If the device is connected via the network and we prefer this connection, then pass in the flag.
        if self.preferNetworkConnection && self.connectionType.contains(.network) {
            ops.rawValue |= IDEVICE_LOOKUP_PREFER_NETWORK.rawValue
        }
        return ops
    }
    /// Readonly: True when the devices uses the network connection, otherwise false.
    public var usesNetwork: Bool {
        return (self.connectionType == .network) ||
               (self.connectionType.contains(.network) && self.preferNetworkConnection)
    }

    // MARK: - Static functions

    // swiftlint:disable cyclomatic_complexity
    /// Start an observer for newly added, paired or removed iOS devices.
    /// - Return: True if the observer could be started, false otherwise.
    @discardableResult
    static func startGeneratingDeviceNotifications() -> Bool {
        guard !IOSDevice.isGeneratingDeviceNotifications else { return false }

        let callback: idevice_event_cb_t = { (event, _: UnsafeMutableRawPointer?) in
            guard let eventT = event?.pointee, let udidT = eventT.udid else { return }

            let udid = String(cString: udidT)
            var notificationName: Notification.Name?

            // Replace the idevice_connection_type with a swift enum
            var conType: ConnectionType = .unknown
            switch eventT.conn_type {
            case CONNECTION_USBMUXD: conType = .usb
            case CONNECTION_NETWORK:
                // Make sure to skip this network device if we only allow USB connections.
                guard IOSDevice.detectNetworkDevices else { return }
                conType = .network
            default: conType = .unknown
            }

            // The existing device isntance or nil if the device does not exist yet.
            var device = deviceList[udid]

            // Determine the correct event to send
            switch eventT.event {
            case IDEVICE_DEVICE_ADD, IDEVICE_DEVICE_PAIRED:
                // Check if the devive is already connected via a different connection type.
                if (device != nil) && !(device!.connectionType.contains(conType)) {
                    // Add the missing connection type to the device.
                    device?.connectionType.insert(conType)
                    notificationName = .DeviceChanged
                    break
                } else if let res = deviceName(udid, conType.lookupOps) {
                    // Create and add the device to the internal device list before sending the notification.
                    device = IOSDevice(UDID: udid, name: String(cString: res), connectionType: conType)
                    notificationName = (eventT.event == IDEVICE_DEVICE_ADD) ? .DeviceConnected : .DevicePaired
                    break
                }

                // Something went wrong. Most likely we can not read the device. Abort.
                return

            case IDEVICE_DEVICE_REMOVE:
                // Remove an existing connectionType from the list.
                if  device?.connectionType.contains(conType) ?? false {
                    device?.connectionType.remove(conType)

                    // If there is no connection type left, we need to disconnect the device.
                    notificationName = (device?.connectionType.isEmpty ?? true) ? .DeviceDisconnected : .DeviceChanged
                    break
                }

                // Something went wrong. Maybe some error in the connection.
                notificationName = .DeviceDisconnected
            default:
                return
            }

            // The deviceList does not store references, therefore write the modified device to the list to update
            // the cached device.
            deviceList[udid] = (notificationName == .DeviceDisconnected) ? nil : device

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: notificationName!, object: nil, userInfo: ["device": device!])
            }
        }

        // Subscribe for new devices events.
        if idevice_event_subscribe(callback, nil) == IDEVICE_E_SUCCESS {
            IOSDevice.isGeneratingDeviceNotifications = true
            return true
        }

        return false
    }
    // swiftlint:enable cyclomatic_complexity

    /// Stop observing device changes.
    /// - Return: True if the observer could be closed, False otherwise.
    @discardableResult
    static func stopGeneratingDeviceNotifications() -> Bool {
        guard IOSDevice.isGeneratingDeviceNotifications else { return false }

        // Remove all currently connected devices.
        deviceList.forEach({
            NotificationCenter.default.post(name: .DeviceDisconnected, object: nil, userInfo: ["device": $1])
        })
        deviceList.removeAll()

        // Cancel device event subscription.
        if idevice_event_unsubscribe() == IDEVICE_E_SUCCESS {
            IOSDevice.isGeneratingDeviceNotifications = false
            return true
        }

        return false
    }

    // MARK: - Initializing Device
    private init(UDID: String, name: String, connectionType: ConnectionType) {
        self.udid = UDID
        self.name = name
        self.connectionType = connectionType
        // Assign the default value
        self.preferNetworkConnection = IOSDevice.preferNetworkConnectionDefault
    }

    // MARK: - Upload Developer Disk Image

    /// Pair the specific iOS Device with this computer and try to upload the DeveloperDiskImage.
    /// - Throws:
    ///    * `DeviceError.pair`: The pairing process failed
    ///    * See `mountDeveloperDiskImage`
    /// - Return: Device instance
    func pair() throws {
        // check if a device is connected
        guard pairDevice(self.udid, self.lookupOps) else {
            throw DeviceError.pair("Could not pair device!")
        }

        // try to mount the DeveloperDiskImage.dmg
        try self.mountDeveloperDiskImage()
    }

    /// Try to upload and mount the DeveloperDiskImage.dmg on this device.
    /// - Throws:
    ///    * `DeviceError.devDiskImageNotFound`: No DeveloperDiskImage.dmg or Signature file found in App Support folder
    ///    * `DeviceError.devDiskImageMount`: Error mounting the DeveloperDiskImage.dmg file
    ///    * `DeviceError.permisson`: Permission error while accessing the App Support folder
    ///    * `DeviceError.productInfo`: Could not read the devices product version string
    private func mountDeveloperDiskImage() throws {
        // developer image is already mounted
        let manager: FileManager = FileManager.default

        // elevate the access privilege level if required
        let startAccess = manager.startAccessingSupportDirectory()
        let isMounted = developerImageIsMountedForDevice(udid, self.lookupOps)
        if startAccess { manager.stopAccessingSupportDirectory() }

        if isMounted {
            return
        }

        if let retVersion: UnsafePointer<Int8> = deviceProductVersion(self.udid, self.lookupOps),
           let retName: UnsafePointer<Int8> = deviceProductName(self.udid, self.lookupOps) {
            // Get the current product version string e.g 12.4
            let productVersion = String(cString: retVersion)
            // Get the current product name e.g. iPhone OS
            let productName = String(cString: retName)
            // get the path to the developer disk images
            if let devDMG: URL = manager.getDeveloperDiskImage(os: productName, version: productVersion),
                let devSign: URL = manager.getDeveloperDiskImageSignature(os: productName, version: productVersion) {

                if !manager.hasDownloadedSupportFiles(os: productName, version: productVersion) {
                    throw DeviceError.devDiskImageNotFound("DeveloperDiskImage not found!", os: productName,
                                                           version: productVersion)
                }

                // try to mount the developer image
                let startAccess = manager.startAccessingSupportDirectory()
                let isMounted = mountImageForDevice(udid, devDMG.path, devSign.path, self.lookupOps)
                if startAccess { manager.stopAccessingSupportDirectory() }

                if !isMounted {
                    throw DeviceError.devDiskImageMount("Mount error!", os: productName, version: productVersion)
                }
            } else {
                throw DeviceError.permisson("Wrong file permission!")
            }
        } else {
            throw DeviceError.productInfo("Could not read device information!")
        }
    }

    // MARK: - Managing locations

    /// Set the device location to the new coordinates.
    /// - Parameter location: new coordinates
    /// - Return: True on success, false otherwise.
    @discardableResult
    func simulateLocation(_ location: CLLocationCoordinate2D) -> Bool {
        return sendLocation("\(location.latitude)", "\(location.longitude)", "\(self.udid)", self.lookupOps)
    }

    /// Stop spoofing the iOS device location and reset the coordinates to the real device coordinates.
    /// - Return: True on success, False otherwise.
    @discardableResult
    func disableSimulation() -> Bool {
        return resetLocation("\(self.udid)", self.lookupOps)
    }
}

extension IOSDevice: Equatable {
    /// We consider a device to be equal if the udid and the connection type is the same.
    /// If the same device is connected twice, once per USB and once per Wi-Fi, this will lead to
    /// two different Device instances.
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.udid == rhs.udid
    }
}
