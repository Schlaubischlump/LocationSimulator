//
//  SeparatorLine.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class SeparatorLine: NSBox {
    override func updateLayer() {
        super.updateLayer()
        // Support dark mode.
        self.borderColor = .separator
    }
}
