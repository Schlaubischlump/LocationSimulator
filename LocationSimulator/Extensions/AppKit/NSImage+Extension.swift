//
//  NSImage+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import AppKit

extension NSImage {
    /// Generate a qr code image from a string.
    /// - Parameter fromString: The string to encode as qr code
    /// - Parameter size: The size of the final image
    static func generateQrCode(_ fromString: String, size: CGSize) -> NSImage? {
        guard let data = fromString.data(using: .utf8) else {
          return nil
        }
        // Filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
          return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
          return nil
        }

        let rep = NSCIImageRep(ciImage: ciImage)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)

        let finalImage = NSImage(size: size)
        finalImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        image.draw(in: NSRect(origin: .zero, size: size))
        finalImage.unlockFocus()

        return finalImage
    }

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

    /// References to images in the asset catalog.
    static var moveImage: NSImage = NSImage(named: "Move")!

    static var controlsImage: NSImage =  NSImage(named: "Controls")!

    static var playImage: NSImage = NSImage(named: "Play")!

    static var pauseImage: NSImage = NSImage(named: "Pause")!

    static var payPalImage: NSImage = NSImage(named: "PayPalLogo")!

    static var githubImage: NSImage = NSImage(named: "GithubLogo")!

    static var ethImage: NSImage = NSImage(named: "EthLogo")!
}
