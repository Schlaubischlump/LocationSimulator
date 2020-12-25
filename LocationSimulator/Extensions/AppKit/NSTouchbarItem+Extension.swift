//
//  NSTouchbarItem+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSTouchBarItem {
    public var isEnabled: Bool {
        get { return (self.view as? NSControl)?.isEnabled ?? true }
        set { (self.view as? NSControl)?.isEnabled = newValue }
    }
}
