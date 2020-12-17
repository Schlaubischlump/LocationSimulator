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
        let windowController = NSApp.mainWindow?.windowController
        let window = windowController?.window

        // Prepare the open file dialog
        let dialog = NSOpenPanel()
        dialog.title                   = NSLocalizedString("CHOOSE_GPX_FILE", comment: "")
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["gpx"]

        let response = dialog.runModal()
        if response == .OK, let gpxFile = dialog.url {

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

                        // Start the navigation of the GPX route
                        if let coords = self.uniqueCoordinates(waypoints: waypoints, routes: routes, tracks: tracks) {
                            // Use the coordinates
                            let viewController = windowController?.contentViewController as? MapViewController
                            // Jump to the first coordinate of the coordinate list
                            viewController?.requestGPXRouting(route: coords)
                        } else {
                            // TODO: Show a user selection window for the waypoints / routes / tracks.
                        }
                    case .failure:
                        // Could not parse the file.
                        window?.showError(NSLocalizedString("ERROR_PARSE_GPX", comment: ""),
                                          message: NSLocalizedString("ERROR_PARSE_GPX_MSG", comment: ""))
                    }
                }
            } catch {
                // Could not open the file.
                window?.showError(NSLocalizedString("ERROR_OPEN_GPX", comment: ""),
                                  message: NSLocalizedString("ERROR_OPEN_GPX_MSG", comment: ""))
            }

        }
    }
}
