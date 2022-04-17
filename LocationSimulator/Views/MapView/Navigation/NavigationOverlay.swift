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
    /// The bounding rect for this route. This value is only updated if you call
    /// `update:activeRoute:inactiveRoute:invalidateBoundingMapRect` method with `invalidateBoundingMapRect` true.
    public var boundingMapRect: MKMapRect

    /// The first coordinate of the route. (0, 0) if the route is empty.
    public var coordinate: CLLocationCoordinate2D {
        var coordinate: CLLocationCoordinate2D?
        self.readCoordinatesAndWait { activeRoute, _ in
            coordinate = activeRoute.first
        }
        return coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    /// The coordinates for the active route.
    private var activeRoute: [CLLocationCoordinate2D]
    /// The coordinates for the inactive route.
    private var inactiveRoute: [CLLocationCoordinate2D]

    /// Internal lock to prevent multiple threads from simultaneously changing the coordinates.
    private let lock = NSLock()

    /// Create a new NavigationOverlay instance with an empty active and inactive path.
    convenience override init() {
        self.init(activePath: [], inactivePath: [])
    }

    /// Create a new NavigationOverlay instance from an active and inactive path.
    /// - Parameter activePath: The path to highlight with the active color
    /// - Parameter inactivePath: The path to highlight with the inactive color
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

    /// Thread safe blocking method to access the current traveled and upcoming coordinates.
    /// - Parameter block: The completion block for the activeRoute and inactiveRoute after access is granted
    public func readCoordinatesAndWait(withBlock block: (_ activeRoute: [CLLocationCoordinate2D],
                                                         _ inactiveRoute: [CLLocationCoordinate2D]) -> Void) {
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
