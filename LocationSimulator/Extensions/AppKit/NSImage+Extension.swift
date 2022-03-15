//
//  NSImage+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import AppKit

extension NSImage {
    /// Get a new resized image instance of this image.
    /// - Parameter width: new image width
    /// - Parameter height: new image height
    /// - Return: resized image
    func resize(width: CGFloat, height: CGFloat) -> NSImage {
        let srcRect = NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let destRect = NSRect(x: 0, y: 0, width: width, height: height)
        let newImage = NSImage(size: destRect.size)
        newImage.lockFocus()
        self.draw(in: destRect, from: srcRect, operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        newImage.size = destRect.size
        return newImage
    }

    /// Tint an image with a color.
    /// - Parameter color: the tint color
    /// - Return: the new tinted NSImage
    func tint(color: NSColor) -> NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            color.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)

            return true
        }
    }

    public var cgImage: CGImage? {
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        return self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }

    /// References to images in the asset catalog.
    static var moveImage: NSImage = NSImage(named: "Move")!

    static var controlsImage: NSImage =  NSImage(named: "Controls")!

    static var playImage: NSImage = NSImage(named: "Play")!

    static var pauseImage: NSImage = NSImage(named: "Pause")!
}
