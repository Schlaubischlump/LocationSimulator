//
//  SearchPopupHandler+MKLocalSearchCompleterDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit

extension SearchPopupController: MKLocalSearchCompleterDelegate {
    /// Called when the searchCompleter finished loading the search results.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Show the matches when the search finished.
        let matches = self.searchCompleter.results.map {
            Match(text: $0.title, detail: $0.subtitle, data: $0)
        }
        self.searchField.showMatches(matches)
    }
}
