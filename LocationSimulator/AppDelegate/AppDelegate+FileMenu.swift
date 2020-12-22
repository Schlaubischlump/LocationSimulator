//
//  AppDelegate+FileMenu.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import CoreLocation
import GPXParser

extension AppDelegate {
    /// Return a list with all coordinates if only a signle type of points is found.
    private func uniqueCoordinates(waypoints: [WayPoint], routes: [Route],
                                   tracks: [Track]) -> [CLLocationCoordinate2D]? {
        // More than one track or route
        if tracks.count > 1 || routes.count > 1 {
            return nil
        }

        // Check if there is a single unique point collection to use
        let routepoints = routes.flatMap { $0.routepoints }
        let trackpoints = tracks.flatMap { $0.segments.flatMap { $0.trackpoints } }
        let points: [[GPXPoint]] = [waypoints, routepoints, trackpoints]
        let filteredPoints = points.filter { $0.count > 0 }

        // Return the coordinates with the unique points.
        return filteredPoints.count == 1 ? filteredPoints[0].map { $0.coordinate } : nil
    }

    /// Open a gpx file.
    @IBAction func openGPXFile(_ sender: NSMenuItem) {
        guard let windowController = NSApp.mainWindow?.windowController, let window = windowController.window else {
            return
        }

        // Prepare the open file dialog
        let title = NSLocalizedString("CHOOSE_GPX_FILE", comment: "")
        let (response, url): (NSApplication.ModalResponse, URL?) = window.showOpenPanel(title, extensions: ["gpx"])

        // Make sure everything is working as expected.
        guard response == .OK, let gpxFile = url else { return }

        do {
            // Try to parse the GPX file
            let parser = try GPXParser(file: gpxFile)
            parser.parse { result in
                switch result {
                case .success:
                    // Successfully opened the file
                    let waypoints = parser.waypoints
                    let routes = parser.routes
                    let tracks = parser.tracks

                    let viewController = windowController.contentViewController as? MapViewController

                    // Start the navigation of the GPX route if there is only one unique route to use.
                    if let coords = self.uniqueCoordinates(waypoints: waypoints, routes: routes, tracks: tracks) {
                        // Jump to the first coordinate of the coordinate list
                        viewController?.requestGPXRouting(route: coords)
                    } else {
                        // Show a user selection window for the waypoints / routes / tracks.
                        let alert = GPXSelectionAlert(tracks: tracks, routes: routes, waypoints: waypoints)
                        alert.beginSheetModal(for: window) { response, coordinates in
                            switch response {
                            case .OK: viewController?.requestGPXRouting(route: coordinates)
                            default: break
                            }
                        }
                    }
                case .failure:
                    // Could not parse the file.
                    window.showError(NSLocalizedString("ERROR_PARSE_GPX", comment: ""),
                                     message: NSLocalizedString("ERROR_PARSE_GPX_MSG", comment: ""))
                }
            }
        } catch {
            // Could not open the file.
            window.showError(NSLocalizedString("ERROR_OPEN_GPX", comment: ""),
                             message: NSLocalizedString("ERROR_OPEN_GPX_MSG", comment: ""))
        }

    }
}
