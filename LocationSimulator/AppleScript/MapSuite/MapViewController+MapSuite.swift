//
//  MapViewController+MapSuite.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension MapViewController {
    @objc var uniqueID: Int {
        let value = self.hash
        let sign = value < 0 ? -1 : 1
        // Applescript has a strange limit for integer...
        return sign * (abs(value) % 536870911)
    }

    @objc var heading: CLLocationDegrees {
        get { return self.getDirectionViewAngle() }
        set { self.rotateDirectionViewTo(newValue) }
    }

    @objc var location: [CGFloat]? {
        get {
            if let loc = self.spoofer?.currentLocation {
                return [loc.latitude, loc.longitude]
            }
            return nil
        }
        set {
            if let coordArr = newValue, let loc = try? arrayToCoordinate(coordArr) {
                self.spoofer?.switchToInteractiveMoveState()
                self.spoofer?.setLocation(loc)
                self.menubarController?.addLocation(loc)
            }
        }
    }

    @objc var automove: Bool {
        get {
            return self.isAutoMoving
        }
        set(newValue) {
            if newValue != self.isAutoMoving {
                self.toggleAutoMove()
            }
        }
    }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        let container = self.view.window?.objectSpecifier
        guard let containerDescription = container?.keyClassDescription as? NSScriptClassDescription else {
            return nil
        }
        return NSUniqueIDSpecifier(containerClassDescription: containerDescription, containerSpecifier: container,
                                   key: "mapViewControllers", uniqueID: self.uniqueID)
    }

    @objc(resetLocation:) private func resetLocation(_ command: NSScriptCommand) {
        self.resetLocation()
    }

    @objc(move:) private func move(_ command: NSScriptCommand) {
        self.move(flip: false)
    }

    @objc(followRoute:) private func followRoute(_ command: NSScriptCommand) {
        guard let coordDescriptors = command.arguments?["route"] as? [NSAppleEventDescriptor] else {
            command.setScriptASError(.InvalidCoordinateList)
            return
        }

        var route = [CLLocationCoordinate2D]()
        for descriptor in coordDescriptors {
            // make sure the coordinate list is valid
            guard descriptor.numberOfItems == 2,
                    let lat = descriptor.atIndex(1)?.doubleValue,
                    let lon = descriptor.atIndex(2)?.doubleValue else {
                command.setScriptASError(.InvalidCoordinateList)
                return
            }

            route += [CLLocationCoordinate2D(latitude: lat, longitude: lon)]
        }

        // Start following the route without asking
        self.teleportToStartAndNavigate(route: route)
    }

    @objc(requestLocationChange:) private func requestLocationChange(_ command: NSScriptCommand) {
        guard let params = command.evaluatedArguments,
              let coordValues = params["to"] as? [CGFloat] else {
            command.setScriptASError(.InvalidCoordinate)
            return
        }

        do {
            let coord = try arrayToCoordinate(coordValues)
            self.requestTeleportOrNavigation(toCoordinate: coord)
        } catch let error {
            command.setScriptError(error)
        }
    }
}
