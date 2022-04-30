//
//  NavigationMenuBarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import LocationSpoofer

let kNavigationMenuTag: Int = 1

/// Enum to represent the main Navigation menu.
enum NavigationMenubarItem: Int, CaseIterable, MenubarItem {
    case walk                   = 0
    case cycle                  = 1
    case drive                  = 2
    case setLocation            = 4
    case toggleAutomove         = 6
    case moveUp                 = 8
    case moveDown               = 9
    case moveRight              = 10
    case moveLeft               = 11
    case stopNavigation         = 12
    case resetLocation          = 13
    case recentLocation         = 14
    case useMacLocation         = 15

    static public var menu: NSMenu? {
        return NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu
    }

    static public func selectMoveItem(forMoveType moveType: MoveType) {
        let menuBarItems: [MoveType: NavigationMenubarItem] = [.walk: .walk, .cycle: .cycle, .drive: .drive]
        menuBarItems.forEach { $1.off() }
        menuBarItems[moveType]?.on()
    }

    /// Use the clockwise / counterclockwise label for the left and right arrow menu items.
    static func useClockwiseCounterClockwiseLabels() {
        NavigationMenubarItem.moveRight.item?.localeKey = "ROTATE_CLOCKWISE_MENUITEM"
        NavigationMenubarItem.moveLeft.item?.localeKey = "ROTATE_COUNTERCLOCKWISE_MENUITEM"
    }

    /// Use the left / right label for the left and right arrow menu items.
    static func useLeftRightLabels() {
        NavigationMenubarItem.moveRight.item?.localeKey = "MOVE_RIGHT_MENUITEM"
        NavigationMenubarItem.moveLeft.item?.localeKey = "MOVE_LEFT_MENUITEM"
    }
}
