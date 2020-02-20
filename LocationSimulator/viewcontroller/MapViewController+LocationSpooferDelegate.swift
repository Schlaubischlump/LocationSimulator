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

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // show a progress spinner when we request a location change
        self.startSpinner()

        // remove the route overlay if it is present
        if (self.routeOverlay != nil) {
            self.mapView.removeOverlay(self.routeOverlay!)
            self.routeOverlay = nil
        }

        // make sure the spoofer is setup
        guard let coord = toCoordinate, let spoofer = self.spoofer else {
            return
        }

        // if there are still points left on the route => update the overlay
        let stepsLeft = spoofer.route.count
        if stepsLeft > 0  {
            self.routeOverlay = MKPolyline(coordinates: [coord] + spoofer.route, count: stepsLeft+1)
            self.mapView.addOverlay(self.routeOverlay!, level: .aboveLabels)
            // FixMe: force a redraw to show the overlay... for some reason display is not working
            // this does block the UI for a little less then a second :/ 
            //self.mapView.setCenter(self.mapView.centerCoordinate, animated: true)
        }
    }

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // hide the spinner
        self.stopSpinner()

        // inform the user that the location could not be changed
        self.view.window!.showError(NSLocalizedString("LOCATION_CHANGE_ERROR", comment: ""),
                                    message: NSLocalizedString((toCoordinate == nil) ?
                                        "LOCATION_RESET_ERROR_MSG" : "LOCATION_CHANGE_ERROR_MSG", comment: ""))
    }

    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {
        // true if the location was reset, false otherwise
        let isReset: Bool = (toCoordinate == nil)

        if isReset {
            // disable all move menubar items when the location is reset
            NavigationMenubarItem.ToggleAutomove.disable()
            NavigationMenubarItem.ResetLocation.disable()
            NavigationMenubarItem.MoveUp.disable()
            NavigationMenubarItem.MoveDown.disable()
            NavigationMenubarItem.MoveClockwise.disable()
            NavigationMenubarItem.MoveCounterclockwise.disable()
        } else {
            // enable these items if we start faking the location
            NavigationMenubarItem.ToggleAutomove.enable()
            NavigationMenubarItem.ResetLocation.enable()
        }

        // calculate the total rounded distance in kilometers
        let totalDistanceInKM: Double = round(self.spoofer?.totalDistance ?? 0.0) / 1000.0
        self.totalDistanceLabel.stringValue = String(format: NSLocalizedString("TOTAL_DISTANCE", comment: ""),
                                                     totalDistanceInKM)

        // hide / show move controls
        self.controlsHidden = isReset

        // hide the progress spinner when the location was changed
        self.stopSpinner()

        // if we have set a new location animate the marker
        if (!isReset) {
            // location was set for the first time => display marker
            if (self.currentLocationMarker == nil) {
                let currentLocationMarker = MKPointAnnotation()
                currentLocationMarker.title = NSLocalizedString("CURRENT_LOCATION", comment: "")

                self.mapView.addAnnotation(currentLocationMarker)
                self.currentLocationMarker = currentLocationMarker
                self.autoFocusCurrentLocation = true

                // Add this location to the recent locations
                RecentLocationMenubarItem.addLocation(toCoordinate!)
            }
            self.currentLocationMarker!.subtitle = "\(toCoordinate!.latitude), \(toCoordinate!.longitude)"

             // location was updated => animate to new position
            NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
                context.allowsImplicitAnimation = true
                self.currentLocationMarker?.coordinate = toCoordinate!
            }, completionHandler: nil)

            if self.autoFocusCurrentLocation {
                self.mapView.setCenter(toCoordinate!, animated: true)
            }
        } else { // the location was reset => remove marker
            if let marker = self.currentLocationMarker {
                self.mapView.removeAnnotation(marker)
                self.currentLocationMarker = nil
            }

            self.autoFocusCurrentLocation = false
        }
    }

    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {
        switch moveState {
            case .manual:
                moveButton.image = #imageLiteral(resourceName: "MoveButton")
                // allow all movement to navigate manual
                NavigationMenubarItem.MoveCounterclockwise.enable()
                NavigationMenubarItem.MoveClockwise.enable()
                NavigationMenubarItem.MoveUp.enable()
                NavigationMenubarItem.MoveDown.enable()
                // we disabled automove => we can not stop the navigation
                NavigationMenubarItem.StopNavigation.disable()
            case .auto:
                moveButton.image = #imageLiteral(resourceName: "MoveButtonAuto")

                // we are moving automatically => do not allow manual movement
                NavigationMenubarItem.MoveUp.disable()
                NavigationMenubarItem.MoveDown.disable()

                if spoofer.route.isEmpty {
                    // allow changing the direction when automoving
                    NavigationMenubarItem.MoveCounterclockwise.enable()
                    NavigationMenubarItem.MoveClockwise.enable()
                } else {
                    // if we are navigating enable the menu item to stop the navigation
                    NavigationMenubarItem.StopNavigation.enable()
                    // disable all movement if we are navigating
                    NavigationMenubarItem.MoveCounterclockwise.disable()
                    NavigationMenubarItem.MoveClockwise.disable()
                }
        }

        if (self.routeOverlay != nil) {
            self.mapView.removeOverlay(self.routeOverlay!)
            self.routeOverlay = nil
        }
    }
}
