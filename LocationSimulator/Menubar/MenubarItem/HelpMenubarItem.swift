//
//  HelpMenuItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit

enum HelpMenubarItem: Int, CaseIterable, MenubarItem {
    case donate = 3

    static public var menu: NSMenu? {
        return NSApp.helpMenu
    }
}
