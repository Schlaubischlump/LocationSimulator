//
//  Window.swift
//  LocationSimulator
//
//  Created by David Klopp on 16.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit

@objc(LSWindow) class Window: NSWindow {
    // Starting with 14.0 (probably earlier) the toolbar is incorrectly layouted if the title is visible
    override var titleVisibility: NSWindow.TitleVisibility {
        get {
            return if #available(macOS 11.0, *) {
                .hidden
            } else {
                super.titleVisibility
            }
        }
        set {
            if #unavailable(macOS 11.0) {
                super.titleVisibility = newValue
            }
        }
    }
}
