//
//  SeparatorLine.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class SeparatorLine: NSBox {
    // Support dark mode.
    override func updateLayer() {
        super.updateLayer()
        self.borderColor = .separator
    }
}
