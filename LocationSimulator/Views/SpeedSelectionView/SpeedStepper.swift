//
//  CoordinateStepper.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

/// NSStepper subclass to support float values.
class SpeedStepper: NSStepper {

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.increment = 0.1
        self.minValue = kMinSpeed
        self.maxValue = kMaxSpeed
    }
}
