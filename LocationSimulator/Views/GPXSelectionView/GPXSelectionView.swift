//
//  GPXSelectionView.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import CoreLocation
import GPXParser

/// A view which allows the user to select a track, track segment, router or waypoints.
class GPXSelectionView: NSView {
    @IBOutlet var contentView: NSView!

    @IBOutlet var browser: NSBrowser!

    /// The input data to consider.
    public var tracks: [Track] = []

    public var routes: [Route] = []

    public var waypoints: [WayPoint] = []

    // MARK: - Constructor

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        // Load the contentView and set its size to update automatically.
        Bundle.main.loadNibNamed("GPXSelectionView", owner: self, topLevelObjects: nil)
        self.contentView.autoresizingMask = [.width, .height]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.contentView.frame = self.bounds
        self.addSubview(self.contentView)

        self.browser.delegate = self
    }

    // MARK: - Coordinates

    /// The coordinates of the selected Track / Tracksegment / Route / Waypoints
    public func getCoordinates() -> [CLLocationCoordinate2D] {
        let firstRow = self.browser.selectedRow(inColumn: 0)
        let secondRow = self.browser.selectedRow(inColumn: 1)

        // Empty selection
        guard firstRow >= 0 else { return [] }

        // Selected a single segment
        if secondRow > 0 {
            return self.tracks[firstRow].segments[secondRow].trackpoints.map { $0.coordinate }
        }
        // Selected a complete track, route or the waypoints.
        if firstRow < self.tracks.count {
            return self.tracks[firstRow].segments.flatMap { $0.trackpoints.map { $0.coordinate } }
        }
        // The waypoints entry was selected, if it was added in the first place
        if self.waypoints.count > 0 && firstRow == self.browser(self.browser, numberOfRowsInColumn: 0) - 1 {
            return waypoints.map { $0.coordinate }
        }
        // Routes where selected
        return self.routes.flatMap { $0.routepoints.map { $0.coordinate } }
    }
}
