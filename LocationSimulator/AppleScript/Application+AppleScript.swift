//
//  LSApplication+AppleScript.swift
//  LocationSimulator
//
//  Created by David Klopp on 06.05.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

func arrayToCoordinate(_ arr: [CGFloat]) throws -> CLLocationCoordinate2D {
    guard arr.count == 2 else {
        throw ASError.InvalidCoordinate
    }
    return CLLocationCoordinate2D(latitude: arr[0], longitude: arr[1])
}

/// Extension to the main Application class to support apple script
extension Application {
    @objc private var devices: [ASDevice] {
        return ASDevice.availableDevices
    }

    @objc private var gpxFiles: [ASGPXFile] {
        return ASGPXFile.openFiles
    }

    @objc(loadGPXFile:) private func loadGPXFile(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let gpxFileURL = params["file"] as? URL else {
            return false
        }

        // Load and parse the input file.
        do {
            return try ASGPXFile(file: gpxFileURL)
        } catch let error {
            command.scriptErrorNumber = (error as NSError).code
            command.scriptErrorString = error.localizedDescription
        }

        return nil
    }

    // MARK: - Coordinate helper functions

    @objc(distanceBetween:) private func distanceBetween(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let position = params["from"] as? [CGFloat],
                let lookAt = params["to"] as? [CGFloat] else {
            return false
        }

        do {
            let positionCoord = try arrayToCoordinate(position)
            let lookAtCoord = try arrayToCoordinate(lookAt)
            return positionCoord.distanceTo(coordinate: lookAtCoord)
        } catch let error {
            command.scriptErrorNumber = (error as NSError).code
            command.scriptErrorString = error.localizedDescription
        }
        return -1
    }

    @objc(sinOf:) private func sinOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let num = params["of"] as? CGFloat else {
            return false
        }
        return sin(num)
    }

    @objc(cosOf:) private func cosOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let num = params["of"] as? CGFloat else {
            return false
        }
        return cos(num)
    }

    @objc(atanOf:) private func atanOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let y = params["y"] as? CGFloat,
                let x = params["x"] as? CGFloat else {
            return false
        }
        return atan2(y, x)
    }
}
