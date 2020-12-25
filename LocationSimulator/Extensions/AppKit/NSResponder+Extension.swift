//
//  NSResponder+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSResponder {
    var menubarController: MenubarController? {
        return (NSApp.delegate as? AppDelegate)?.menubarController
    }
}
