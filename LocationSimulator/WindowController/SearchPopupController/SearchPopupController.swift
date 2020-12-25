//
//  SerachPopupHandler.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit

/// This class is responsible for handling the search, displaying the results and perform the action when a result is
/// selected.
class SearchPopupController: NSResponder {
    /// The corresponding window controller.
    @IBOutlet weak var windowController: WindowController!

    /// Search for a location inside the map.
    @IBOutlet weak var searchField: LocationSearchField! {
        didSet {
            // Setup the table view delegate to handle the textfield input and the result selection.
            self.searchField.tableViewDelegate = self
        }
    }

    /// A reference to the main window belonging to this controller.
    public var window: NSWindow? {
        return self.windowController?.window
    }

    /// A reference to the current mapViewController if available.
    public var mapViewController: MapViewController? {
        return self.windowController?.mapViewController
    }

    /// Search completer to find a location based on a string.
    public var searchCompleter = MKLocalSearchCompleter()

    // MARK: - Constructor

    private func setup() {
        // Setup the delegate to hand the search results.
        if #available(OSX 10.15, *) {
            self.searchCompleter.resultTypes = .address
        } else {
            self.searchCompleter.filterType = .locationsOnly
        }
        self.searchCompleter.delegate = self
    }

    override init() {
        super.init()
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
}
