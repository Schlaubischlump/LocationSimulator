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
    @IBInspectable var lat: Double = 37.3305976
    @IBInspectable var long: Double = -122.0265794


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
