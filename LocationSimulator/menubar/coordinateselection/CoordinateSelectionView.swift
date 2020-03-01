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

class CoordinateSelectionView: NSView {
    @IBOutlet var contentView: NSView!

    @IBOutlet var longTextField: NSTextField!
    @IBOutlet var latTextField: NSTextField!

    @IBOutlet var longStepper: LongStepper!
    @IBOutlet var latStepper: LatStepper!

    @IBInspectable var lat: Double = 37.3305976 {
        didSet {
            self.lat = lat >= 0 ? min(85, self.lat) : max(self.lat, -85)
            self.latTextField.doubleValue = self.lat
            self.latStepper.doubleValue = self.lat
        }
    }

    @IBInspectable var long: Double = -122.0265794 {
        didSet {
            self.long = long >= 0 ? min(180, self.long) : max(self.long, -180)
            self.longTextField.doubleValue = self.long
            self.longStepper.doubleValue = self.long
        }
    }
    

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        // Load the contentView and set its size to update automatically.
        Bundle.main.loadNibNamed("CoordinateSelectionView", owner: self, topLevelObjects: nil)
        self.contentView.autoresizingMask = [.width, .height]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.contentView.frame = self.bounds
        self.addSubview(self.contentView)
    }

    public func getCoordinates() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.lat, longitude: self.long)
    }
}
