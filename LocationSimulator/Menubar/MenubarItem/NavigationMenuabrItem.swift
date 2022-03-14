//
//  NavigationMenuBarItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

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
    case moveCounterclockwise   = 10
    case moveClockwise          = 11
    case stopNavigation         = 12
    case resetLocation          = 13
    case recentLocation         = 14
    case useMacLocation         = 15

    static public var menu: NSMenu? {
        return NSApp.menu?.item(withTag: kNavigationMenuTag)?.submenu
    }

    static public func selectMoveItem(forMoveType moveType: MoveType) {
        let menuBarItems: [MoveType: NavigationMenubarItem] = [.walk: .walk, .cycle: .cycle, .car: .drive]
        menuBarItems.forEach { $1.off() }
        menuBarItems[moveType]?.on()
    }
}
