//
//  ViewMenuBarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kViewMenuTag: Int = 3

/// The main File menu.
enum ViewMenubarItem: Int, CaseIterable, MenubarItem {
    case toggleSidebar = 3

    static public var menu: NSMenu? {
        return NSApp.menu?.item(withTag: kViewMenuTag)?.submenu
    }
}
