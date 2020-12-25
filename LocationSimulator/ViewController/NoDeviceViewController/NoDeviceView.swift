//
//  NoDeviceView.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class NoDeviceView: NSView {

    /// The imageView in the view's center.
    @IBOutlet var imageView: NSImageView!
    /// The title label below the imageView.
    @IBOutlet var titleLabel: NSTextField!
    /// The detailed label below the title label.
    @IBOutlet var detailedLabel: NSTextField!

    // MARK: - Constructor

    public func set(title: String, message: String) {
        // Set the `no device` text when the view finished loading.
        self.titleLabel.stringValue = title
        self.detailedLabel.stringValue = message
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Apply a nice fade to the imageView.
        let bounds = self.imageView.bounds
        let insetRect = bounds.insetBy(dx: 5, dy: 5)
        let maskLayer = CALayer()
        maskLayer.frame = bounds
        maskLayer.shadowRadius = 5
        maskLayer.shadowPath = CGPath(roundedRect: insetRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = .zero
        maskLayer.shadowColor = NSColor.controlBackgroundColor.cgColor

        self.imageView.layer?.mask = maskLayer
    }
}
