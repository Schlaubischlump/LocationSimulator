//
//  NSColor+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSColor {
    static let highlight = NSColor(named: "HighlightColor")!
    static let separator = NSColor(named: "SeparatorColor")!
    static let overlayBlue = NSColor(named: "OverlayBlueColor")!
    static let darkOverlayBlue = NSColor(named: "DarkOverlayBlueColor")!
    static let currentLocationBlue = NSColor(named: "CurrentLocationBlueColor")!

    func withAdjustedBrightness(_ value: CGFloat) -> NSColor {
        var red: CGFloat    = 0.0
        var green: CGFloat  = 0.0
        var blue: CGFloat   = 0.0
        var alpha: CGFloat  = 0.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        red     = max(0, min(1, red+value))
        green   = max(0, min(1, green+value))
        blue    = max(0, min(1, blue+value))
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
