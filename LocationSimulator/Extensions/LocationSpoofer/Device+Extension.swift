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
        guard let components = self.version?.split(separator: "."), !components.isEmpty else {
            return nil
        }
        return components.count == 1 ? (components[0] + ".0") : (components[0] + "." + components[1])
    }

    /// Pair a new device by uploading the developer disk image if required.
    /// - Throws:
    ///    * `DeviceError.devDiskImageNotFound`: No DeveloperDiskImage.dmg or Signature file found in the support folder
    ///    * `DeviceError.devDiskImageMount`: Error mounting the DeveloperDiskImage.dmg file
    ///    * `DeviceError.permisson`: Permission error while accessing the App Support folder
    ///    * `DeviceError.productInfo`: Could not read the devices product version or name
    public func pair() throws {
        // Only real iOS Devices require a pairing
        guard let device = self as? IOSDevice else { return }

        // Only continue if the DeveloperDiskImage is not already mounted
        guard !device.developerDiskImageIsMounted else {
            return
        }

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
        if let devDiskImage = fileManager.getDeveloperDiskImage(os: productName, version: productVersion),
           let devDiskSig = fileManager.getDeveloperDiskImageSignature(os: productName, version: productVersion) {

            // Make sure the files are downlaod
            guard fileManager.hasDownloadedSupportFiles(os: productName, version: productVersion) else {
                throw DeviceError.devDiskImageNotFound("DeveloperDiskImage not found!")
            }

            try device.pair(devImage: devDiskImage, devImageSig: devDiskSig)
        } else {
            throw DeviceError.permisson("Wrong file permission!")
        }
    }
}
