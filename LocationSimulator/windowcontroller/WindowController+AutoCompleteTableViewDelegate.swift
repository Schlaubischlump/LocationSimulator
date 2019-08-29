//
//  WindowController+AutoCompleteTableViewDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import MapKit

extension WindowController: AutoCompleteTableViewDelegate {
    /**
     Called when an item is selected inside the autocompletion popup.
     - Parameter textField: autocompletion text field instance
     - Parameter item: selected item as match object
     */
    func textField(_ textField: NSTextField, didSelectItem item: Match) {
        guard let comp = item.data as! MKLocalSearchCompletion?,
            let viewController = contentViewController as? MapViewController else {
                return
        }

        let request: MKLocalSearch.Request = MKLocalSearch.Request(completion: comp)
        let localSearch: MKLocalSearch = MKLocalSearch(request: request)

        localSearch.start { (response, error) in
            if error == nil, let res: MKLocalSearch.Response = response {
                viewController.mapView.setRegion(res.boundingRegion, animated: true)
                self.window?.makeFirstResponder(viewController.mapView)
            }
        }
    }

    /**
     Called when text is entered into the textField.
     - Parameter textField: autocompletion text field instance
     - Parameter words:
     - Parameter charRange:
     - Parameter index:
     - Return: list of matches for the entered search string
     */
    func textField(_ textField: NSTextField, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: Int) -> [Match] {

        self.searchCompleter.queryFragment = textField.stringValue
        return self.searchCompleter.results.map { Match(text: $0.title, detail: $0.subtitle, data: $0) }
    }
}
