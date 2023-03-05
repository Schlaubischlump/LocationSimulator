//
//  LocationManager.swift
//  LocationSimulator
//
//  Created by David Klopp on 04.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case unknown
    case restricted
    case denied
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    /// Internal reference to a location manager for this mac's location
    private let manager = CLLocationManager()

    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var onError: ((Error) -> Void)?

    var locationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    override init() {
        super.init()
        self.manager.delegate = self
    }

    func requestLocationAndPermissionIfRequired() {
        if self.requestPermissionIfRequired() {
            self.manager.requestLocation()
        }
    }

    @discardableResult
    private func requestPermissionIfRequired(status: CLAuthorizationStatus = .notDetermined) -> Bool {
        switch status {
        case .authorized, .authorizedAlways:
            return true
        case .notDetermined:
            // Request permission
            if #available(macOS 11.0, *) {
                self.manager.requestWhenInUseAuthorization()
            } else if #available(macOS 10.15, *) {
                self.manager.requestAlwaysAuthorization()
            }
            self.manager.desiredAccuracy = kCLLocationAccuracyBest
            return true
        case .restricted:
            self.onError?(LocationError.restricted)
            return false
        case .denied:
            self.onError?(LocationError.denied)
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #unavailable(macOS 11.0) {
            self.requestPermissionIfRequired(status: status)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(macOS 11.0, *) {
            self.requestPermissionIfRequired(status: manager.authorizationStatus)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.manager.stopUpdatingLocation()
        // Only if we really have no current location
        guard manager.location == nil else {
            return
        }
        self.onError?(error)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.manager.stopUpdatingLocation()

        guard let location = locations.first else {
            return
        }
        self.onLocation?(location.coordinate)
    }
}
