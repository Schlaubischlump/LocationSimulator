//
//  SidebarStyle.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import AppKit

enum SidebarStyle {
    /// The default sidebar style where the content behind the window is shown.
    case standard
    /// A sidebar style where the sidebar is drawn in front of the MapView.
    case inFrontOfMap

    var blendingMode: NSVisualEffectView.BlendingMode {
        switch self {
        case .standard: return .behindWindow
        case .inFrontOfMap: return .withinWindow
        }
    }

    var material: NSVisualEffectView.Material {
        switch self {
        case .standard: return .sidebar
        case .inFrontOfMap: return .titlebar
        }
    }
}
