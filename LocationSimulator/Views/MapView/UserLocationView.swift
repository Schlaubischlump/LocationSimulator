//
//  UserLocationView.swift
//  LocationSimulator
//
//  Created by David Klopp on 14.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import MapKit

class UserLocationView: MKAnnotationView {
    public var colorDotInset: CGFloat = 3 {
        didSet {
            guard self.superview != nil else { return }
            self.rebuildLayers()
        }
    }

    public var pulseAnimationDuration: TimeInterval = 1.5 {
        didSet {
            guard self.superview != nil else { return }
            self.rebuildLayers()
        }
    }

    public var delayBetweenPulseCycles: TimeInterval = 0 {
        didSet {
            guard self.superview != nil else { return }
            self.rebuildLayers()
        }
    }

    public var annotationColor = NSColor(calibratedRed: 0, green: 0.478, blue: 1.0, alpha: 1.0) {
        didSet {
            guard self.superview != nil else { return }
            self.rebuildLayers()
        }
    }

    public var outerColor: NSColor = .white {
        didSet {
            guard self.superview != nil else { return }
            self.rebuildLayers()
        }
    }

    private var outerDotLayer: CALayer?
    private var colorDotLayer: CALayer?

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        self.wantsLayer = true
        self.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.frame = CGRect(x: 0, y: 0, width: 22, height: 22)

        self.calloutOffset = CGPoint(x: 0, y: 4)
        self.canShowCallout = true
        self.collisionMode = .circle
        self.isDraggable = true
        self.displayPriority = .required
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func rebuildLayers() {
        self.layer?.removeAllAnimations()

        self.outerDotLayer?.removeFromSuperlayer()
        self.outerDotLayer = createOuterDotLayer()

        self.colorDotLayer?.removeFromSuperlayer()
        self.colorDotLayer = createColorDotLayer()

        self.layer?.addSublayer(self.outerDotLayer!)
        self.layer?.addSublayer(self.colorDotLayer!)
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        guard newSuperview != nil else { return }
        self.rebuildLayers()
    }

    public func createOuterDotLayer() -> CALayer {
        let outerDotLayer = CALayer()
        outerDotLayer.bounds = self.bounds
        outerDotLayer.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        outerDotLayer.backgroundColor = self.outerColor.cgColor
        outerDotLayer.cornerRadius = self.bounds.width/2
        outerDotLayer.contentsGravity = .center
        outerDotLayer.shadowColor = .black
        outerDotLayer.shadowOffset = CGSize(width: 0, height: 2)
        outerDotLayer.shadowRadius = 3
        outerDotLayer.shadowOpacity = 0.3
        outerDotLayer.opacity = Float(self.outerColor.alphaComponent)
        outerDotLayer.shouldRasterize = true
        outerDotLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 1.0
        return outerDotLayer
    }

    public func createPulseAnimationGroup() -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.duration = self.pulseAnimationDuration + self.delayBetweenPulseCycles
        group.repeatCount = .infinity
        group.autoreverses = true
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: .default)

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        pulseAnimation.fromValue = 0.8
        pulseAnimation.toValue = 1.0
        pulseAnimation.duration = self.pulseAnimationDuration

        group.animations = [pulseAnimation]
        return group
    }

    func createColorDotLayer() -> CALayer {
        let colorDotLayer = CALayer()
        let width = self.bounds.size.width - self.colorDotInset*2
        colorDotLayer.bounds = CGRect(x: 0, y: 0, width: width, height: width)
        colorDotLayer.allowsGroupOpacity = true
        colorDotLayer.backgroundColor = self.annotationColor.cgColor
        colorDotLayer.cornerRadius = width/2
        colorDotLayer.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        colorDotLayer.shouldRasterize = true
        colorDotLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 1.0

        guard self.delayBetweenPulseCycles != .infinity else { return colorDotLayer }

        DispatchQueue.global(qos: .userInitiated).async {
            let animationGroup = self.createPulseAnimationGroup()

            DispatchQueue.main.async {
                self.colorDotLayer?.add(animationGroup, forKey: "pulse")
            }
        }

        return colorDotLayer
    }
}
