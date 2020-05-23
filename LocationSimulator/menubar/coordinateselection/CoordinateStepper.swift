//
//  CoordinateStepper.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class CoordinateStepper: NSStepper {

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.increment = 0.0000001
    }
}

class LatStepper: CoordinateStepper {
    override func commonInit() {
        super.commonInit()
        self.minValue = -85
        self.maxValue = 85
    }
}

class LongStepper: CoordinateStepper {
    override func commonInit() {
        super.commonInit()
        self.minValue = -180
        self.maxValue = 180
    }
}
