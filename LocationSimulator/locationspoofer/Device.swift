//
//  Device.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

public enum ConnectionType: Int {
    case UNKNOWN = 0 // This should never be the case, unless libimobiledevice is changed
    case USB = 1
    case NETWORK = 2
}

/// Error messages while connecting a device.
public enum DeviceError: Error {
    case pair(_ message: String)
    case permisson(_ message: String)
    case devDiskImageNotFound(_ message: String, iOSVersion: String)
    case devDiskImageMount(_ message: String, iOSVersion: String)
    case productVersion(_ message: String)
}

/// Notifications when a device is connected / paired / disconnected.
public extension Notification.Name {
    static let DevicePaired = Notification.Name("iDevicePaired")
    static let DeviceConnected = Notification.Name("iDeviceConntected")
    static let DeviceDisconnected = Notification.Name("iDeviceDisconntected")
}

class Device {
    /// Unique Device ID (UDID) string.
    public var UDID: String = ""

    /// Try to read the product version string from the connected iOS device.
    lazy public var productVersion: String? = {

        if let ret: UnsafePointer<Int8> = deviceProductVersion(UDID) {
            return String(cString: ret)
        }
        return nil
    }()

    // MARK: - Class functions

    /**
     Start to observer the USB interface for newly added, paired or removed iOS devices.
     - Return: True if the observer could be started, False otherwise.
     */
    @discardableResult
    class func startGeneratingDeviceNotifications() -> Bool {
        let callback: idevice_event_cb_t = { (event, userData: UnsafeMutableRawPointer?) in
            guard let eventT = event?.pointee else { return }
            guard let udidT = eventT.udid else { return }

            let udid = String(cString: udidT)
            var name: String = ""
            var notificationName: Notification.Name?

            switch eventT.event {
            case IDEVICE_DEVICE_ADD, IDEVICE_DEVICE_PAIRED:
                notificationName = (eventT.event == IDEVICE_DEVICE_ADD) ? .DeviceConnected : .DevicePaired
                if let res = deviceName(udid) {
                    name = String(cString: res)
                    break
                }
                return
            case IDEVICE_DEVICE_REMOVE:
                notificationName = .DeviceDisconnected
            default:
                return
            }

            DispatchQueue.main.async {
                // replace the idevice_connection_type with a swift enum
                var conType: ConnectionType = .UNKNOWN
                switch eventT.conn_type {
                case CONNECTION_USBMUXD:
                    conType = .USB
                case CONNECTION_NETWORK:
                    conType = .NETWORK
                default:
                    conType = .UNKNOWN
                }

                NotificationCenter.default.post(name: notificationName!, object: nil,
                                                userInfo: ["UDID": udid, "NAME": name, "CONTYPE": conType])
            }
        }
        return idevice_event_subscribe(callback, nil) == IDEVICE_E_SUCCESS
    }

    /**
     Stop observing the USB interface for device changes.
     - Return: True if the observer could be closed, False otherwise.
     */
    @discardableResult
    class func stopGeneratingDeviceNotifications() -> Bool {
        return idevice_event_unsubscribe() == IDEVICE_E_SUCCESS
    }

    /**
     Pair the specific iOS Device with this computer and try to upload the DeveloperDiskImage.
    - Throws:
        * `DeviceError.pair`: The pairing process failed
        * See `mountDeveloperDiskImage`
     - Return: Device instance
     */
    class func load(_ UDID: String) throws -> Device {
        // check if a device is connected
        guard pairDevice(UDID) else {
            throw DeviceError.pair(NSLocalizedString("PAIR_ERROR_MSG", comment: ""))
        }

        // pair and verify was successfull => create device instance
        let device = Device(UDID: UDID)

        // try to mount the DeveloperDiskImage.dmg
        try device.mountDeveloperDiskImage()

        return device
    }

    // MARK: - Initializing Device
    convenience init(UDID: String) {
        self.init()
        self.UDID = UDID
    }

    // MARK: - Upload Developer Disk Image

    /**
     Try to upload and mount the DeveloperDiskImage.dmg on this device.
     - Throws:
        * `DeviceError.devDiskImageNotFound`: No DeveloperDiskImage.dmg or Signature file found in App Support folder
        * `DeviceError.devDiskImageMount`: Error mounting the DeveloperDiskImage.dmg file
        * `DeviceError.permisson`: Permission error while accessing the App Support folder
        * `DeviceError.productVersion`: Could not read the devices product version string
     */
    func mountDeveloperDiskImage() throws {
        // developer image is already mounted
        if developerImageIsMountedForDevice(UDID) {
            return
        }

        if let productVersion = self.productVersion {
            // get the path to the developer disk images
            let manager: FileManager = FileManager.default
            if let devDMG: URL = manager.getDeveloperDiskImage(iOSVersion: productVersion),
                let devSign: URL = manager.getDeveloperDiskImageSignature(iOSVersion: productVersion) {
                var isDir: ObjCBool = false
                if !manager.fileExists(atPath: devDMG.path, isDirectory: &isDir)
                    || isDir.boolValue
                    || !manager.fileExists(atPath: devSign.path, isDirectory: &isDir)
                    || isDir.boolValue {
                    throw DeviceError.devDiskImageNotFound(NSLocalizedString("DEVDISK_NOT_FOUND", comment: ""),
                                                           iOSVersion: productVersion)
                }

                // try to mount the developer image
                if !mountImageForDevice(UDID, devDMG.path, devSign.path) {
                    throw DeviceError.devDiskImageMount(NSLocalizedString("MOUNT_ERROR", comment: ""),
                                                        iOSVersion: productVersion)
                }
            } else {
                throw DeviceError.permisson(NSLocalizedString("PERMISSION_ERROR", comment: ""))
            }
        } else {
            throw DeviceError.productVersion(NSLocalizedString("PRODUCT_VERSION_ERROR", comment: ""))
        }
    }

    // MARK: - Managing locations

    /**
     Set the device location to the new coordinates.
     - Parameter location: new coordinates
     - Return: True on success, False otherwise.
     */
    @discardableResult
    func simulateLocation(_ location: CLLocationCoordinate2D) -> Bool {
        return sendLocation("\(location.latitude)", "\(location.longitude)", "\(self.UDID)")
    }

    /**
     Stop spoofing the iOS device location and reset the coordinates to the real device coordinates.
     - Return: True on success, False otherwise.
     */
    @discardableResult
    func disableSimulation() -> Bool {
        return resetLocation("\(self.UDID)")
    }
}
