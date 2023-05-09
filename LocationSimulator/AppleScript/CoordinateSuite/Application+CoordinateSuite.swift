//
//  Application.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public enum ASTransportType: UInt32 {
    case walk  = 0x4C737761 // Lswa
    case cycle = 0x4C736379 // Lscy
    case drive = 0x4C736472 // Lsdr

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .walk: return .walking
        case .cycle: return .walking
        case .drive: return .automobile
        }
    }
}

internal func arrayToCoordinate(_ arr: [CGFloat]) throws -> CLLocationCoordinate2D {
    guard arr.count == 2 else {
        throw ASError.InvalidCoordinate
    }
    return CLLocationCoordinate2D(latitude: arr[0], longitude: arr[1])
}

extension Application {
    @objc(distanceBetween:) private func distanceBetween(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let position = params["from"] as? [CGFloat],
                let lookAt = params["to"] as? [CGFloat] else {
            command.setScriptASError(.InvalidCoordinate)
            return nil
        }

        do {
            let positionCoord = try arrayToCoordinate(position)
            let lookAtCoord = try arrayToCoordinate(lookAt)
            return positionCoord.distanceTo(coordinate: lookAtCoord)
        } catch let error {
            command.setScriptError(error)
        }
        return nil
    }

    @objc(isValid:) private func isValid(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
              let coordValues = params["coordinate"] as? [CGFloat] else {
            command.setScriptASError(.InvalidCoordinate)
            return nil
        }

        do {
            let coord = try arrayToCoordinate(coordValues)
            return CLLocationCoordinate2DIsValid(coord)
        } catch let error {
            command.setScriptError(error)
        }
        return -1
    }

    @objc(route:) private func route(_ command: NSScriptCommand) -> [Any]? {
        guard let params = command.evaluatedArguments,
              let from = params["from"] as? [CGFloat],
              let to = params["to"] as? [CGFloat] else {
            command.setScriptASError(.InvalidCoordinate)
            return nil
        }

        var transportType: ASTransportType = .walk
        if let transportTypeRawValue = params["transportType"] as? UInt32 {
            transportType = ASTransportType(rawValue: transportTypeRawValue)!
        }

        do {
            let fromLoc = try arrayToCoordinate(from)
            let toLoc = try arrayToCoordinate(to)
            var result: [Any]?
            var isFinished: Bool = false

            fromLoc.calculateRouteTo(toLoc, transportType: transportType.mkTransportType) { coords in
                result = coords.map { coord in
                    let coordList = NSAppleEventDescriptor.list()
                    coordList.insert(NSAppleEventDescriptor(double: coord.latitude), at: 1)
                    coordList.insert(NSAppleEventDescriptor(double: coord.longitude), at: 2)
                    return coordList
                }
                isFinished = true
            }

            // Wait for the result to make this call synchronous.
            // A semaphore is not working, because the route is calculated in the main thread.
            // This is ugly as f***. I'm aware of that. If you have a better idea how to solve this, let me now.
            var steps = 10
            while !isFinished {
                CFRunLoopRunInMode(.defaultMode, 0.5, false)

                // Throw a timeout error if we need to long
                steps -= 1
                if steps <= 0 {
                    throw ASError.Timeout
                }
            }

            return result ?? []
        } catch let error {
            command.setScriptError(error)
        }
        return []
    }
}
