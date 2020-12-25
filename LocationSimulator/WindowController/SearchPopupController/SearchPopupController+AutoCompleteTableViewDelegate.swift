//
//  SearchPopupHandler+AutoCompleteTableViewDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit

extension SearchPopupController: AutoCompleteTableViewDelegate {
    /// Called when an item is selected inside the autocompletion popup.
    /// - Parameter textField: autocompletion text field instance
    /// - Parameter item: selected item as match object
    func textField(_ textField: NSTextField, didSelectItem item: Match) {
        guard let comp = item.data as? MKLocalSearchCompletion else { return }

        let request: MKLocalSearch.Request = MKLocalSearch.Request(completion: comp)
        let localSearch: MKLocalSearch = MKLocalSearch(request: request)

        // Zoom into the searched location.
        localSearch.start { (response, error) in
            if error == nil, let res: MKLocalSearch.Response = response {
                self.mapViewController?.zoomTo(region: res.boundingRegion)
            }
        }
    }

    /// Called when text is entered into the textField.
    /// - Parameter textField: autocompletion text field instance
    /// - Parameter: text: the entered stringValue inside of the textField
    func textField(_ textField: NSTextField, textDidChange text: String) {
        // Cancel any running search request.
        if self.searchCompleter.isSearching {
            self.searchCompleter.cancel()
        }

        // Clear the results or start a search.
        if textField.stringValue.isEmpty {
            self.searchField.showMatches([])
        } else {
            self.searchCompleter.queryFragment = textField.stringValue
        }
    }
}
