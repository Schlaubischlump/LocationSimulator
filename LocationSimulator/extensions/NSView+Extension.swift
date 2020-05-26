//
//  NSView+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import AppKit

extension NSView {
    /// Set a new anchor point for a view without graphic glitches.
    /// - Parmater anchorPoint: new anchor point for this view
    func setAnchorPoint(_ anchorPoint: CGPoint) {
        guard let layer = self.layer else { return }

        let width = bounds.size.width
        let height = bounds.size.height
        var newPoint = NSPoint(x: width * anchorPoint.x, y: height * anchorPoint.y)
        var oldPoint = NSPoint(x: width * layer.anchorPoint.x, y: height * layer.anchorPoint.y)

        newPoint = newPoint.applying(layer.affineTransform())
        oldPoint = oldPoint.applying(layer.affineTransform())

        var position = layer.position
        //position.x = position.x - oldPoint.x + newPoint.x
        //position.y = position.y - oldPoint.y + newPoint.y
        position.x += newPoint.x - oldPoint.x
        position.y += newPoint.y - oldPoint.y

        layer.position = position
        layer.anchorPoint = anchorPoint
    }
}
