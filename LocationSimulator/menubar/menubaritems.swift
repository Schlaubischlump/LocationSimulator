//
//  Constants.swift
//  LocationSimulator
//
//  Created by David Klopp on 15.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
import AppKit

enum MenubarItem: Int {
    case Walk                   = 0
    case Cycle                  = 1
    case Drive                  = 2
    case SetLocation            = 4
    case ToggleAutomove         = 6
    case MoveUp                 = 8
    case MoveDown               = 9
    case MoveCounterclockwise   = 10
    case MoveClockwise          = 11
    case StopNavigation         = 12
    case ResetLocation          = 13

    // MARK: - Enable or disable a menubar item

    private func setEnabled(_ enabled: Bool) {
        guard let navigationMenu = NSApp.menu?.item(withTag: 1)?.submenu else { return }
        navigationMenu.item(withTag: self.rawValue)?.isEnabled = enabled
    }

    func enable() {
        self.setEnabled(true)
    }

    func disable() {
        self.setEnabled(false)
    }
}
