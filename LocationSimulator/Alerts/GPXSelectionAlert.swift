//
//  GPXSelectionAlert.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import GPXParser
import CoreLocation

typealias GPXSelectionCompletionHandler = ((NSApplication.ModalResponse, [CLLocationCoordinate2D]) -> Void)

/// Alert view which manages and shows the gpx track, track segment, route and waypoints selection.
class GPXSelectionAlert: NSAlert {
    public var gpxSelectionView: GPXSelectionView? {
        return self.accessoryView as? GPXSelectionView
    }

    /// Default constructor.
    /// - Parameter tracks: all track of the gpx file
    /// - Parameter routes: all routes of the gpx file
    /// - Parameter waypoints: all waypoints of the gpx file
    init(tracks: [Track], routes: [Route], waypoints: [WayPoint]) {
        super.init()

        self.messageText = NSLocalizedString("GPX_SELECTION", comment: "")
        self.informativeText = NSLocalizedString("GPX_SELECTION_MSG", comment: "")
        self.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        self.addButton(withTitle: NSLocalizedString("CHOOSE", comment: ""))

        // Initialise the GPXSelectionView.
        let gpxView = GPXSelectionView(frame: CGRect(x: 0, y: 0, width: 330, height: 100))
        gpxView.tracks = tracks
        gpxView.routes = routes
        gpxView.waypoints = waypoints
        self.accessoryView = gpxView

    }

    override func beginSheetModal(for sheetWindow: NSWindow,
                                  completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        fatalError("Do not use this function. Use the two argument implementation instead.")
    }

    /// Implementation to handle the response more nicely and add a second argument.
    func beginSheetModal(for sheetWindow: NSWindow,
                         completionHandler handler: GPXSelectionCompletionHandler? = nil) {
        super.beginSheetModal(for: sheetWindow) { [unowned self] response in
            // If the user did not select anything, we just assume an empty selection and cancel the operation.
            let coordinates = self.gpxSelectionView?.getCoordinates() ?? []
            switch response {
            case .alertFirstButtonReturn: handler?(.cancel, coordinates)
            case .alertSecondButtonReturn: handler?(coordinates.isEmpty ? .cancel : .OK, coordinates)
            default: break
            }
        }
    }

}
