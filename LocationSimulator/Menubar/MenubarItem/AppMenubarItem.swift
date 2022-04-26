//
//  AppMenubarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit

let kAppMenuTag: Int = 4

enum AppMenubarItem: Int, CaseIterable, MenubarItem {
    case preferences = 2

    static public var menu: NSMenu? {
        return NSApp.menu?.item(withTag: kAppMenuTag)?.submenu
    }
}
