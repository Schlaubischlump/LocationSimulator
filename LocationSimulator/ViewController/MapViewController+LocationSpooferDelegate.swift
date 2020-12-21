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
        self.startSpinner()

        // remove the route overlay if it is present
        self.mapView.removeNavigationOverlay()

        // make sure the spoofer is setup
        guard let coord = toCoordinate, let spoofer = self.spoofer else { return }

        // if we are still navigating => update the overlay
        if spoofer.route.count > 0 {
            self.mapView.addNavigationOverlay(withPath: [coord] + spoofer.route)
        }
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)
        let errorMsg = isReset ? "LOCATION_RESET_ERROR_MSG" : "LOCATION_CHANGE_ERROR_MSG"

        // hide the spinner
        self.stopSpinner()

        // inform the user that the location could not be changed
        self.view.window!.showError(NSLocalizedString("LOCATION_CHANGE_ERROR", comment: ""),
                                    message: NSLocalizedString(errorMsg, comment: ""))
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)

        // Calculate the total rounded distance in kilometers and update the label
        let totalDistanceInKM: Double = round(self.spoofer?.totalDistance ?? 0.0) / 1000.0
        self.totalDistanceLabel.stringValue = String(format: NSLocalizedString("TOTAL_DISTANCE", comment: ""),
                                                     totalDistanceInKM)

        // Hide the progress spinner after the location was changed.
        self.stopSpinner()

        if isReset {
            // Disable all `move` menubar items when the location is reset.
            MenubarController.state = .connected
            //  Remove the current location marker
            self.mapView.removeCurrentLocationMarker()
            // Disable autofocus
            self.autoFocusCurrentLocation = false
            // Hide the movement controls
            self.contentView?.controlsHidden = true
        } else {
            // We either have teleported or navigated. In each case update the menubar.
            switch spoofer.moveState {
            case .manual: MenubarController.state = .manual
            case .auto:   MenubarController.state = spoofer.route.isEmpty ? .auto : .navigation
            }
            // Place the current location marker
            let markerCreated = self.mapView.placeCurrentLocationMarker(atLocation: toCoordinate!)
            // Add this location to the recent locations if the marker was created.
            // If the marker was moved (automove / navigate) we do not want to add
            // the location to the recent location list
            if markerCreated {
                RecentLocationMenubarItem.addLocation(toCoordinate!)
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
    }

    // MARK: - Move state

    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {
        switch moveState {
        case .manual:
            // Remove the movebutton highlight
            self.contentView?.movementButtonHUD.highlight = false
            // allow all movement to navigate manual
            MenubarController.state = .manual
        case .auto:
            // Highlight the move button
            self.contentView?.movementButtonHUD.highlight = true
            // we are moving automatically or navigating
            MenubarController.state = spoofer.route.isEmpty ? .auto : .navigation
        }

        // Remove the navigation overlay. We need to do this even if we are navigating.
        // On navigation the overlay will be removed and readded on location will change.
        // This will fake the animation. There is no easier why to animate the navigation.
        self.mapView.removeNavigationOverlay()
    }
}
