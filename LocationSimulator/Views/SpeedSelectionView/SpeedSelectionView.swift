//
//  SetLocationView.swift
//  LocationSimulator
//
//  Created by David Klopp on 12.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CoreLocation

/// A view which allows the user to enter a speed value in km/h.
class SpeedSelectionView: NSView {
    @IBOutlet var contentView: NSView!

    @IBOutlet var textField: NSTextField!

    @IBOutlet var label: NSTextField! {
        didSet { self.label.stringValue = "SPEED".localized + ":" }
    }

    @IBOutlet var stepper: SpeedStepper!

    /// The speed in km/h
    @IBInspectable var speed: Double = 10.0 {
        didSet {
            self.speed = max(min(self.speed, kMaxSpeed), kMinSpeed)
            self.textField.doubleValue = self.speed
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        // Load the contentView and set its size to update automatically.
        Bundle.main.loadNibNamed("SpeedSelectionView", owner: self, topLevelObjects: nil)
        self.contentView.autoresizingMask = [.width, .height]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.contentView.frame = self.bounds
        self.addSubview(self.contentView)
    }

    /// Get the speed entered by the used.
    /// - Return: the speed value in km / h
    public func getSpeed() -> Double {
        return self.speed
    }
}
