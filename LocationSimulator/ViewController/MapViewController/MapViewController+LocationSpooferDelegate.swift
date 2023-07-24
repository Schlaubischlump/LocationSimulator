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
import LocationSpoofer
import CLogger

extension MapViewController: LocationSpooferDelegate {

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // Update the window title on macOS 11.0 and up
        self.geocodingTask?.update(toLocation: toCoordinate)
        // Show a progress spinner when we request a location change
        self.contentView?.startSpinner()
        // Make sure the spoofer is setup
        guard let coord = toCoordinate, coord != spoofer.currentLocation else { return }

        // Update the overlay if we are currently navigating
        if case .navigation(let route) = spoofer.moveState {
            let traveledRoute = Array(route.traveledCoordinates) + [coord]
            let upcomingRoute = [coord] + Array(route.upcomingCoordinates)
            self.mapView.updateNavigationOverlay(withInactiveRoute: traveledRoute, activeRoute: upcomingRoute)

            // Update the heading according to the current navigation
            let heading = spoofer.currentLocation?.heading(toLocation: coord) ?? 0
            self.rotateDirectionViewTo(heading)
        }
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)
        let errorMsg = isReset ? "LOCATION_RESET_ERROR_MSG" : "LOCATION_CHANGE_ERROR_MSG"

        // hide the spinner
        self.contentView?.stopSpinner()

        // inform the user that the location could not be changed
        self.view.window!.showError("LOCATION_CHANGE_ERROR", message: errorMsg)
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)

        // Calculate the total rounded distance in meters and update the label
        let distanceInMeter = round(spoofer.totalDistance)
        self.contentView?.setTotalDistance(meter: distanceInMeter)

        // Hide the progress spinner after the location was changed.
        self.contentView?.stopSpinner()
        // The new application status.
        var status: DeviceStatus = .connected

        if isReset {
            //  Remove the current location marker
            self.mapView.removeCurrentLocationMarker()
            // Disable autofocus
            self.autofocusCurrentLocation = true
            // Hide the movement controls
            self.contentView?.controlsHidden = true
            // Reset to manual movement
            spoofer.moveState = .manual
        } else {
            // We either have teleported or navigated. In each case update the status.
            switch spoofer.moveState {
            case .manual:       status = .manual
            case .auto:         status = .auto
            case .navigation:   status = .navigation
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
            if self.autofocusCurrentLocation && !self.mapView.isUserMovingTheMap {
                // Center the view, without zooming in.
                self.mapView.setCenter(toCoordinate!, animated: true)
                // self.mapView.zoomToLocation(toCoordinate!, animated: true)
            }
            // Show the movement controls
            self.contentView?.controlsHidden = false

            // Start the auto update only if required
            self.startMoveOnStandingStill()
        }

        // Post the update for the current app status.
        NotificationCenter.default.post(name: .StatusChanged, object: self, userInfo: [
            "device": spoofer.device,
            "status": status
        ])
    }

    // MARK: - Move state

    func didChangeMoveState(spoofer: LocationSpoofer, fromMoveState: MoveState) {
        logDebug("LocationSpoofer: Did change MoveState: \(spoofer.moveState.caseName)")

        // The new application status.
        var status: DeviceStatus = .connected

        // Remove the animation overlay if the navigation was finished or canceled.
        self.mapView.removeNavigationOverlay()

        switch spoofer.moveState {
        case .manual:
            self.contentView?.movementDirectionHUD.isUserInteractionEnabled = true
            // Remove the movebutton highlight
            self.contentView?.movementButtonHUD.highlight = false
            // Allow all movement to navigate manual
            status = .manual
            // Hide or show the pause indicator depeding on wether we are currently navigating
            self.contentView?.hidePlayPauseIndicator()
            // Start moving on standing still
            self.startMoveOnStandingStill()
        case .auto:
            self.contentView?.movementDirectionHUD.isUserInteractionEnabled = true
            // Highlight the move button
            self.contentView?.movementButtonHUD.highlight = true
            // Update the status to disable all manual navigation elements
            status = .auto
            // Show the automove indicator
            self.contentView?.showPauseIndicator()
            spoofer.startAutoUpdate()
        case .navigation(let route):
            self.contentView?.movementDirectionHUD.isUserInteractionEnabled = false
            self.contentView?.movementButtonHUD.highlight = true
            status = .navigation
            self.contentView?.showPauseIndicator()
            // Add the overlay if a new animation was started
            self.mapView.updateNavigationOverlay(withInactiveRoute: Array(route.traveledCoordinates),
                                                 activeRoute: Array(route.upcomingCoordinates))
            spoofer.startAutoUpdate()
        }

        // Update the current application status.
        NotificationCenter.default.post(name: .StatusChanged, object: self, userInfo: [
            "device": spoofer.device,
            "status": (spoofer.currentLocation != nil) ? status : .connected
        ])
    }

    func didChangeAutoUpdate(spoofer: LocationSpoofer, fromValue: Bool) {
        guard case .navigation(let route) = spoofer.moveState else {
            return
        }

        if spoofer.isAutoUpdating {
            self.contentView?.showPauseIndicator()
        } else {
            self.contentView?.showPlayIndicator()

            // If we finished the navigation then change back to interactive movement
            if route.isFinished {
                if self.autoreverseRoute {
                    var coords = route.coordinates
                    coords.reverse()
                    spoofer.switchToNavigationState(coords)
                    spoofer.startAutoUpdate()
                } else {
                    spoofer.switchToInteractiveMoveState()
                }
            }
        }
    }
}
