//
//  NSImageView+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSImageView {
    func tint(color: NSColor) {
        guard let image = self.image else { return }
        self.image = image.tint(color: color)
    }
}
