//
//  FileMenuBarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kFileMenuTag: Int = 2

/// The main File menu.
enum FileMenubarItem: Int, MenubarItem {
    case openGPXFile = 1

    static public var menu: NSMenu? {
        return NSApp.menu?.item(withTag: kFileMenuTag)?.submenu
    }
}
