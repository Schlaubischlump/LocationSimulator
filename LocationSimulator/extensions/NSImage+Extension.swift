//
//  NSImage+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

extension NSImage {
    /**
     Get a new resized image instance of this image.
     - Parameter width: new image width
     - Parameter height: new image height
     - Return: resized image
     */
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
}
