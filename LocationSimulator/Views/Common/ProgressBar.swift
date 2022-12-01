//
//  ProgressBar.swift
//  ProgressBar
//
//  Created by David Klopp on 29.11.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//
import Cocoa

let kAnimationDuration = 0.5

public class ProgressBar: NSView {
    /// The color shown for the portion of the progress bar that is filled.
    public var progressTintColor: NSColor = .systemBlue

    /// The color shown for the portion of the progress bar that is not filled.
    public var trackTintColor = NSColor(name: nil) { appearance in
        let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let colorValue = isDarkMode ? 0.28 : 0.89
        return NSColor(red: colorValue, green: colorValue, blue: colorValue, alpha: 1.0)
    }

    /// The current progress of the progress bar.
    @objc public dynamic var progress: Float = 0.5 {
        didSet {
            self.progress = min(max(self.progress, 0), 1)
            self.setNeedsDisplay(self.bounds)
        }
    }

    public override class func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        switch key {
        case "progress":
            let anim = CABasicAnimation()
            anim.duration = kAnimationDuration
            anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            return anim
        default:
            return super.defaultAnimation(forKey: key)
        }
    }

    /*public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }*/

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        // track bar
        self.drawBar(context: context, color: self.trackTintColor, includeShadow: true)
        // progress bar
        self.drawBar(context: context, color: self.progressTintColor, progress: CGFloat(self.progress))
    }

    public func setProgress(_ progress: Float, animated: Bool) {
        if animated {
            self.animator().progress = progress
        } else {
            self.progress = progress
        }
    }

    private func drawBar(context: CGContext, color: NSColor, progress: CGFloat = 1.0, includeShadow: Bool = false) {
        let lineHeight = self.bounds.height
        let midY = self.bounds.midY
        let progressEndX = (progress * self.frame.width) - midY
        context.setStrokeColor(color.cgColor)
        context.beginPath()
        context.setLineWidth(lineHeight)
        // uncomment this to make the slider start at true zero
        // context.move(to: CGPoint(x: midY-(3*midY*(1-progress)), y: midY))
        // context.addLine(to: CGPoint(x: progressEndX, y: midY))
        context.move(to: CGPoint(x: midY, y: midY))
        context.addLine(to: CGPoint(x: max(midY, progressEndX), y: midY))
        context.setLineCap(.round)
        context.strokePath()

        guard includeShadow else { return }

        context.saveGState()

        let shadowColor: NSColor = .black.withAlphaComponent(0.1)
        let blurRadius: CGFloat = 1.5
        let offset = CGSize(width: 0, height: 0)

        let opaqueShadowColor = shadowColor.withAlphaComponent(1.0).cgColor
        let path = CGPath(roundedRect: self.bounds, cornerWidth: midY, cornerHeight: midY, transform: nil)

        context.addPath(path)
        context.clip()

        context.setAlpha(shadowColor.alphaComponent)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setShadow(offset: offset, blur: blurRadius, color: opaqueShadowColor)
        context.setBlendMode(.sourceOut)
        context.setFillColor(opaqueShadowColor)
        context.addPath(path)
        context.fillPath()

        context.endTransparencyLayer()
        context.restoreGState()
    }

    /*override public func layout() {
        super.layout()
        self.layer?.cornerRadius = self.bounds.height/2
    }

    func setup() {
        self.wantsLayer = true
        self.layer?.masksToBounds = true
    }*/
}
