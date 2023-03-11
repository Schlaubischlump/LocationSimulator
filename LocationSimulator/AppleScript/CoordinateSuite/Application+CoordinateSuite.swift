//
//  Application.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

private func arrayToCoordinate(_ arr: [CGFloat]) throws -> CLLocationCoordinate2D {
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

    @objc(isValid:) private func isValid(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
              let coordValues = params["coordinate"] as? [CGFloat] else {
            return false
        }

        do {
            let coord = try arrayToCoordinate(coordValues)
            return CLLocationCoordinate2DIsValid(coord)
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
