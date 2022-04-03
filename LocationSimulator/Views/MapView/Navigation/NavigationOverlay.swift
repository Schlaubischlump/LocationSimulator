//
//  NavigationOverlay.swift
//  LocationSimulator
//
//  Created by David Klopp on 31.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CoreLocation
import MapKit

class NavigationOverlay: NSObject, MKOverlay {
    public var boundingMapRect: MKMapRect

    public var coordinate: CLLocationCoordinate2D {
        var coordinate: CLLocationCoordinate2D?
        self.readCoordinatesAndWait { activeRoute, _ in
            coordinate = activeRoute.first
        }
        return coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    public var activeRoute: [CLLocationCoordinate2D]
    public var inactiveRoute: [CLLocationCoordinate2D]

    private let lock = NSLock()

    convenience override init() {
        self.init(activePath: [], inactivePath: [])
    }

    public init(activePath: [CLLocationCoordinate2D], inactivePath: [CLLocationCoordinate2D]) {
        self.activeRoute = activePath
        self.inactiveRoute = inactivePath
        self.boundingMapRect = MKMapRect(x: 0, y: 0, width: 0, height: 0)

        super.init()
    }

    deinit {
        self.lock.unlock()
    }

    /// Update the active and inactive Route. This function is thread safe.
    /// - Parameter activeRoute: The new active route
    /// - Parameter inactiveRoute: The new inactive route
    /// - Parameter invalidateBoundingMapRect: Recalculate the new bounding map rect based on the routes
    public func update(activeRoute: [CLLocationCoordinate2D],
                       inactiveRoute: [CLLocationCoordinate2D],
                       invalidateBoundingMapRect: Bool = false
    ) -> MKMapRect {
        defer {
            self.lock.unlock()
        }

        self.lock.lock()

        self.inactiveRoute = inactiveRoute
        self.activeRoute = activeRoute

        if invalidateBoundingMapRect {
            self.boundingMapRect = self.calculateBoundingRect()
        }

        return self.boundingMapRect
    }

    public func readCoordinatesAndWait(withBlock block: ([CLLocationCoordinate2D], [CLLocationCoordinate2D]) -> Void) {
        defer {
            self.lock.unlock()
        }

        self.lock.lock()

        block(self.inactiveRoute, self.activeRoute)
    }

    /// Calculate the bounding map rect based on all coordinates in the active and inactive route.
    private func calculateBoundingRect() -> MKMapRect {
        var points = self.inactiveRoute + self.activeRoute
        guard !points.isEmpty else {
            return MKMapRect(x: 0, y: 0, width: 0, height: 0)
        }

        let point = points.removeFirst()
        let size = MKMapSize(width: 0, height: 0)

        let initialRect = MKMapRect(origin: MKMapPoint(point), size: size)
        return points.reduce(initialRect) { result, nextCoord in
            result.union(MKMapRect(origin: MKMapPoint(nextCoord), size: size))
        }
    }
}
