//
//  PreferenceViewControllerBase.swift
//  LocationSimulator
//
//  Created by David Klopp on 03.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit

let kMaxPreferenceViewWidth = 400.0

class PreferenceViewControllerBase: NSViewController {
    public func widthToFit() {
        // Update the frame width to fit the largest element.
        var xOff = 0.0
        var width = 0.0
        self.view.subviews.forEach {
            ($0 as? NSTextField)?.sizeToFit()
            width = max(width, $0.frame.maxX)
            xOff = max(xOff, $0.frame.minX)
        }
        self.view.frame.size.width = min(kMaxPreferenceViewWidth, width + xOff)
    }
}
