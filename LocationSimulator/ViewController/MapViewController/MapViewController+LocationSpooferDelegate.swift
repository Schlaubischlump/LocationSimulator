//
//  MapViewController+LocationSpooferDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import AppKit
import MapKit

extension MapViewController: LocationSpooferDelegate {

    // MARK: - Location

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // show a progress spinner when we request a location change
        self.contentView?.startSpinner()

        // remove the route overlay if it is present to fake an animation
        self.mapView.removeNavigationOverlay()

        // make sure the spoofer is setup
        guard let coord = toCoordinate, let spoofer = self.spoofer else { return }

        // if we are still navigating => update the overlay
        if !spoofer.route.isEmpty {
            self.mapView.addNavigationOverlay(withPath: [coord] + spoofer.route)
        }
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)
        let errorMsg = isReset ? "LOCATION_RESET_ERROR_MSG" : "LOCATION_CHANGE_ERROR_MSG"

        // hide the spinner
        self.contentView?.stopSpinner()

        // inform the user that the location could not be changed
        self.view.window!.showError(NSLocalizedString("LOCATION_CHANGE_ERROR", comment: ""),
                                    message: NSLocalizedString(errorMsg, comment: ""))
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)

        // Calculate the total rounded distance in meters and update the label
        let distanceInMeter = round(self.spoofer?.totalDistance ?? 0.0)
        self.contentView?.setTotalDistance(meter: distanceInMeter)

        // Hide the progress spinner after the location was changed.
        self.contentView?.stopSpinner()
        // The new application status.
        var status: DeviceStatus = .connected

        if isReset {
            //  Remove the current location marker
            self.mapView.removeCurrentLocationMarker()
            // Disable autofocus
            self.autoFocusCurrentLocation = true
            // Hide the movement controls
            self.contentView?.controlsHidden = true
        } else {
            // We either have teleported or navigated. In each case update the status.
            switch spoofer.moveState {
            case .manual: status = .manual
            case .auto:   status = spoofer.route.isEmpty ? .auto : .navigation
            }
            // Place the current location marker
            let markerCreated = self.mapView.placeCurrentLocationMarker(atLocation: toCoordinate!)
            // Add this location to the recent locations if the marker was created.
            // If the marker was moved (automove / navigate) we do not want to add
            // the location to the recent location list
            if markerCreated {
                self.menubarController?.addLocation(toCoordinate!)
            }
            // If autofocus is enabled and the user is not interacting with the map.
            if  self.autoFocusCurrentLocation && !self.mapView.isUserInteracting {
                // Center the view, without zooming in.
                self.mapView.setCenter(toCoordinate!, animated: true)
                //self.mapView.zoomToLocation(toCoordinate!, animated: true)
            }
            // Show the movement controls
            self.contentView?.controlsHidden = false
        }

        // Post the update for the current app status.
        NotificationCenter.default.post(name: .StatusChanged, object: self, userInfo: [
            "status": status
        ])
    }

    // MARK: - Move state

    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {
        // The new application status.
        var status: DeviceStatus = .connected

        switch moveState {
        case .manual:
            // Remove the movebutton highlight
            self.contentView?.movementButtonHUD.highlight = false
            // allow all movement to navigate manual
            status = .manual
        case .auto:
            // Highlight the move button
            self.contentView?.movementButtonHUD.highlight = true
            // we are moving automatically or navigating
            status = spoofer.route.isEmpty ? .auto : .navigation
        }

        // Remove the animatoon overlay if a navigation was canceled.
        self.mapView.removeNavigationOverlay()

        // Update the current application status.
        NotificationCenter.default.post(name: .StatusChanged, object: self, userInfo: [
            "status": status
        ])
    }
}
