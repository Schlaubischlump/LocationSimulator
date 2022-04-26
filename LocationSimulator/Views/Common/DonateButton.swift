//
//  DonateButton.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit

let kDonateYellow = NSColor(red: 245/255.0, green: 198/255.0, blue: 87/255.0, alpha: 1.0)
let kDonateTextBlue = NSColor(red: 0, green: 104/255.0, blue: 218/255.0, alpha: 1.0)

class DonateButton: NSButton {
    private var backgroundColor: NSColor? {
        didSet {
            self.layer?.backgroundColor = self.backgroundColor?.cgColor
        }
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.bezelStyle = .texturedSquare
        self.isBordered = false
        self.wantsLayer = true
        self.layer?.masksToBounds = false

        self.font = .systemFont(ofSize: 16, weight: .medium)
        self.contentTintColor = kDonateTextBlue
        self.backgroundColor = kDonateYellow
    }

    override func layout() {
        super.layout()
        self.layer?.cornerRadius = self.frame.height/2
        // self.layer?.borderWidth = 1
        // self.layer?.borderColor = NSColor.lightGray.cgColor
        self.layer?.shadowOffset = CGSize(width: 1, height: 1)
        self.layer?.shadowColor = .black
        self.layer?.shadowRadius = 1
        self.layer?.shadowOpacity = 0.1
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.backgroundColor = kDonateYellow.withAdjustedBrightness(0.04)
        self.contentTintColor = kDonateTextBlue.withAdjustedBrightness(-0.1)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.backgroundColor = kDonateYellow
        self.contentTintColor = kDonateTextBlue
    }
}
