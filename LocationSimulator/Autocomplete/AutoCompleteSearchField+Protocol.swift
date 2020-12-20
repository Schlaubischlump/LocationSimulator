//
//  NSTableRowView+Protocol.swift
//  LocationSimulator
//
//  Created by fancymax on 15/12/12.
//  Modified by David Klopp on 11/08/19.
//  Copyright © 2015年 fancy. All rights reserved.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

protocol AutoCompleteTableViewDelegate: AnyObject {
    /// Called whenever the textField text changes. Use `showMatches:` on the AutoCompleteTextField to display
    /// search results.
    func textField(_ textField: NSTextField, textDidChange text: String)

    /// Called when an item is selected.
    func textField(_ textField: NSTextField, didSelectItem item: Match)
}

extension AutoCompleteTableViewDelegate {
    func textField(_ textField: NSTextField, didSelectItem item: Match) {}
}
