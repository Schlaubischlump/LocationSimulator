//
//  LocationSearchField.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class LocationSearchField: AutoCompleteTextField {
    /// Define the width of the popover to be the same width as the textfield.
    override var popOverWidth: CGFloat {
        get {
            return self.frame.size.width - (self.autoCompleteTableView?.intercellSpacing.width ?? 0)
        }
        //swiftlint:disable unused_setter_value
        set {}
        //swiftlint:enable unused_setter_value
    }

}
