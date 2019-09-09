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
    /**
     Calculate the distance from this location to the given one.
     - Parameter coordinate: coordinate to which the distance should be calculated to
     - Return: distance between the two locations
     */
    func distanceTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return thisLocation.distance(from: otherLocation)
    }

    /**
     Calculate a route from this location to the destination and return a list of intermediate locations.
     - Parameter destination: target location
     - Parameter transportType: transport type, e.g car or walk
     - Parameter completion: completion block after the calculation finished
     */
    func calculateRouteTo(_ destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType,
                          completion: @escaping (_ value: [CLLocationCoordinate2D]) -> ()) {

        // create a request to navigation from source to destination
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.transportType = transportType
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        // calculate the route and call the completion block afterwards
        directions.calculate { response, error in
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

    /**
     Calculate the heading from this location to the target location in degrees
     See: https://stackoverflow.com/questions/6924742/valid-way-to-calculate-angle-between-2-cllocations
     - Parameter to: target location
     - Return: heading in degrees
     */
    func heading(to: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians

        let lat2 = to.latitude.degreesToRadians
        let lon2 = to.longitude.degreesToRadians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let headingDegrees = atan2(y, x).radiansToDegrees
        return headingDegrees >= 0 ? headingDegrees : headingDegrees + 360
    }
}
