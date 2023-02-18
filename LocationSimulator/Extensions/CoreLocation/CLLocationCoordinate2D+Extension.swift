//
//  CLLocationCoordinate2D+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension FloatingPoint {
    /// Convert degrees to radians
    var degreesToRadians: Self { return self * .pi / 180 }
    /// Convert radians to degrees
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension CLLocationCoordinate2D {
    /// Calculate the distance from this location to the given one.
    /// - Parameter coordinate: coordinate to which the distance should be calculated to
    /// - Return: distance between the two locations in meter
    func distanceTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return thisLocation.distance(from: otherLocation)
    }

    /// Calculate a route from this location to the destination and return a list of intermediate locations.
    /// - Parameter destination: target location
    /// - Parameter transportType: transport type, e.g car or walk
    /// - Parameter completion: completion block after the calculation finished
    func calculateRouteTo(_ destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType,
                          completion: @escaping (_ value: [CLLocationCoordinate2D]) -> Void) {

        // create a request to navigation from source to destination
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.transportType = transportType
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        // calculate the route and call the completion block afterwards
        directions.calculate { response, _ in
            guard let unwrappedResponse = response else { return }

            DispatchQueue.main.async {
                if let route = unwrappedResponse.routes.first {
                    completion(route.polyline.coordinates)
                } else {
                    completion([])
                }
            }
        }
    }

    /// Get the location name based on the current coordinates.
    @discardableResult
    func getLocationName(completion: @escaping (_ location: CLLocation, _ name: String) -> Void) -> CLGeocoder {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: self.latitude, longitude: self.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, _ -> Void in
            guard let placeMark = placemarks?.first else { return }

            // Street address
            var components: [String] = []
            if let country = placeMark.country {
                components.append(country)
            }
            if let city = placeMark.subAdministrativeArea {
                components.append(city)
            }
            if let street = placeMark.thoroughfare {
                components.append(street)
            }

            completion(location, components.joined(separator: " - "))
        })
        return geoCoder
    }
}
