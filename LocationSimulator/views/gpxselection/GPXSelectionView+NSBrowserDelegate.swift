//
//  GPXSelectionView+NSBrowserDelegat.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import GPXParser

/// We always display the following layout:
/// > Note: There is no submenu for routes or waypoints
///
///  ------------------------       ----------------------------------------
/// | Track 1 - Name Track 1 | =>  | Track Segment 1 - Name Track Segment 1 |
/// |------------------------|     |----------------------------------------|
/// | Track 2 - Name Track 1 |     | Track Segment 2 - Name Track Segment 2 |
/// |------------------------|     |----------------------------------------|
/// | Route 1 - Name Route 1 |     | ...                                    |
/// |------------------------|     |----------------------------------------|
/// | Waypoints              |
///  ------------------------

extension GPXSelectionView: NSBrowserDelegate {

    func browser(_ sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
        // Column 0: Tracks + Routes + Waypoints
        if column == 0 {
            return self.tracks.count + self.routes.count + (self.waypoints.count > 0 ? 1 : 0)
        }

        // Column 1: Selected a track.
        if column == 1 {
            let selectedRowInColumn0 = browser.selectedRow(inColumn: 0)
            if selectedRowInColumn0 < self.tracks.count {
                return self.tracks[selectedRowInColumn0].segments.count
            }
        }

        return 0
    }

    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        guard let cell = cell as? NSBrowserCell else { return }

        if column == 0 {
            // We want to display a track, a route or the waypoints
            if row < self.tracks.count {
                let track = self.tracks[row]
                let name: String = track.name != nil ? " - " + track.name! : ""
                cell.title = NSLocalizedString("TRACK", comment: "") + " \(row + 1)" + name
            } else if self.waypoints.count > 0 && row == self.browser(browser, numberOfRowsInColumn: 0) - 1 {
                cell.title = NSLocalizedString("WAYPOINTS", comment: "")
                cell.isLeaf = true
            } else {
                let route = self.routes[row]
                let name: String = route.name != nil ? " - " + route.name! : ""
                cell.title = NSLocalizedString("ROUTE", comment: "") + " \(row + 1)" + name
                cell.isLeaf = true
            }
        } else {
            // We want to display all track segments
            let selectedRowInColumn0 = browser.selectedRow(inColumn: 0)
            let segment = self.tracks[selectedRowInColumn0].segments[row]
            let name: String = segment.name != nil ? " - " + segment.name! : ""
            cell.title = NSLocalizedString("TRACK_SEGMENT", comment: "") + " \(row + 1)" + name
            cell.isLeaf = true
        }
    }
}
