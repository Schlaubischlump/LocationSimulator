//
//  DeviceError.swift
//  LocationSimulator2
//
//  Created by David Klopp on 24.09.20.
//

import Foundation

/// Error messages while connecting to a device.
public enum DeviceError: Error {
    case pair(_ message: String)
    case permisson(_ message: String)
    case devDiskImageNotFound(_ message: String, iOSVersion: String)
    case devDiskImageMount(_ message: String, iOSVersion: String)
    case productVersion(_ message: String)
}
