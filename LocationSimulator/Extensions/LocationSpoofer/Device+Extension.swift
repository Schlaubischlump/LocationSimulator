//
//  Device+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 06.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import LocationSpoofer

extension Device {
    /// Get the current iOS Version in major.minor format, without any additional revision number.
    public var majorMinorVersion: String? {
        guard let majorVersion = majorVersion else {
            return nil
        }
        return "\(majorVersion).\(minorVersion)"
    }

    public func enabledDeveloperModeToggleInSettings() {
        // Only real iOS Devices require developer mode
        guard let device = self as? IOSDevice else { return }
        device.enabledDeveloperModeToggleInSettings()
    }

    /// Pair a new device by uploading the developer disk image if required.
    /// - Throws:
    ///    * `DeviceError.devDiskImageNotFound`: Required DeveloperDiskImage support file not found
    ///    * `DeviceError.devDiskImageMount`: Error mounting the DeveloperDiskImage file
    ///    * `DeviceError.devMode`: Developer mode is not enabled
    ///    * `DeviceError.permisson`: Permission error while accessing the App Support folder
    ///    * `DeviceError.productInfo`: Could not read the devices product version or name
    public func pair() throws {
        // Only real iOS Devices require a pairing if the DeveloperDiskImage is not already mounted
        guard let device = self as? IOSDevice, !device.developerDiskImageIsMounted else { return }

        // Make sure the C-backend can read the files
        let fileManager = FileManager.default
        let startAcccess = fileManager.startAccessingSupportDirectory()

        // No matter how we leave the function, stop accessing the support directory
        defer {
            if startAcccess {
                fileManager.stopAccessingSupportDirectory()
            }
        }

        // Make sure we got the product information
        guard let productVersion = device.majorMinorVersion, let productName = device.productName else {
            throw DeviceError.productInfo("Could not read device information!")
        }

        // Read the developer disk images
        let developerDiskImage = DeveloperDiskImage(os: productName, version: productVersion)

        // Make sure the developer disk image exists
        guard let devDiskImage = developerDiskImage.imageFile else {
            throw DeviceError.devDiskImageNotFound("DeveloperDiskImage.dmg not found!")
        }

        do {
            if developerDiskImage.hasDownloadedPersonalizedImageFiles {
                // Upload personalized image
                guard let devDiskTrust = developerDiskImage.trustcacheFile else {
                    throw DeviceError.devDiskImageNotFound("DeveloperDiskImage.dmg.trustcache not found!")
                }

                guard let devDiskManifest = developerDiskImage.buildManifestFile else {
                    throw DeviceError.devDiskImageNotFound("BuildManifest.plist not found!")
                }
                // TODO: Upload the personalized image
            } else if developerDiskImage.hasDownloadedImageFiles {
                // Upload traditional DeveloperDiskImage
                guard let devDiskSig = developerDiskImage.signatureFile else {
                    throw DeviceError.devDiskImageNotFound("DeveloperDiskImage.dmg.signature not found!")
                }

                try device.pair(devImage: devDiskImage, devImageSig: devDiskSig)
            } else {
                throw DeviceError.devDiskImageNotFound("DeveloperDiskImage not found!")
            }
        } catch {
            throw DeviceError.permisson("Wrong file permission!")
        }
    }
}
