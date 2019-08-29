//
//  BlurView.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit


class BlurView: NSView {

    // MARK: - Properties

    public var saturation: CGFloat = 2.0 {
        didSet {
            self.reloadFilters()
        }
    }

    public var blurRadius: CGFloat = 20.0 {
        didSet {
            self.reloadFilters()
        }
    }

    /// Change the views tintColor
    public var tintColor: NSColor = NSColor(calibratedWhite: 1.0, alpha: 0.7) {
        didSet {
            self.layer?.backgroundColor =  self.tintColor.cgColor
            self.layer?.setNeedsDisplay()
        }
    }

    /// Apply a maskImage to the view
    public var maskImage: NSImage? {
        didSet {
            guard let viewLayer = self.layer else { return }

            if let image = self.maskImage {
                let maskLayer: CALayer = CALayer()
                maskLayer.contents = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                viewLayer.mask = maskLayer
                maskLayer.frame = viewLayer.bounds
            } else {
                viewLayer.contents = nil
            }
        }
    }


    /// Disable the blur and saturation effect.
    public var disableBlur: Bool = false {
        didSet {
            self.reloadFilters()
        }
    }


    // MARK: - Constructor + public functions

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setup()
    }

    /**
     Reset the filters to the default values.
     */
    public func setDefaults() {
        self.blurRadius = 20.0
        self.saturation = 2.0
        self.reloadFilters()
    }


    // MARK: - Private functions

    /**
     Configure the the view to be layer backed and load the filters.
     */
    private func setup() {
        self.wantsLayer = true
        self.layerUsesCoreImageFilters = true

        self.layer?.needsDisplayOnBoundsChange = true

        self.reloadFilters()
    }

    /**
     Reload the blur and saturation filter with the new values.
     */
    private func reloadFilters() {
        var filters: [CIFilter] = []
        if !self.disableBlur {
            // increase the saturation
            let saturationFilter: CIFilter = CIFilter(name: "CIColorControls")!
            saturationFilter.setDefaults()
            saturationFilter.setValue(self.saturation, forKey: "inputSaturation")

            // create a blur filter
            let blurFilter = CIFilter(name: "CIGaussianBlur")!
            blurFilter.setDefaults()
            blurFilter.setValue(self.blurRadius, forKey: "inputRadius")

            filters = [saturationFilter, blurFilter]
        }

        // apply the filters
        self.layer?.backgroundFilters = filters
        self.layer?.setNeedsDisplay()
    }
}
