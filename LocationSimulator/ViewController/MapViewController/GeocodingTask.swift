//
//  GeocodingTask.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

/// Simple class that performs reverse gecoding to find the name of a location and calls an update function.
/// Only significant location changes are considered.
class GeocodingTask {
    /// Only update the location name if the distance change more than this value.
    var significantLocationUpdateDistance: CLLocationDistance = 250
    /// The current geocded location.
    private(set) var location: CLLocationCoordinate2D?
    /// The current internal geocoder instance.
    private var geocoder: CLGeocoder?
    /// Callback function when the location changes significantly.
    var onUpdate: ((_ locationName: String) -> Void)?

    init(_ onUpdate: ((String) -> Void)? = nil) {
        self.onUpdate = onUpdate
    }

    func update(toLocation: CLLocationCoordinate2D?) {
        // Location reset
        guard let destination = toLocation else {
            self.location = nil
            self.cancel()
            self.onUpdate?("")
            return
        }

        // Location did not change significantly
        if let loc = self.location, loc.distanceTo(coordinate: destination) < self.significantLocationUpdateDistance {
            return
        }

        self.cancel()

        self.location = destination
        self.geocoder = destination.getLocationName { [weak self] (_, name) in
            self?.onUpdate?(name)
        }
    }

    func cancel() {
        if let geocoder = geocoder, geocoder.isGeocoding {
            self.geocoder?.cancelGeocode()
        }
    }
}
