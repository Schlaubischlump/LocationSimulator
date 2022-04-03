//
//  UserLocationView.swift
//  LocationSimulator
//
//  Created by David Klopp on 14.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import MapKit

class UserLocationView: MKAnnotationView {
    public static var defaultSize: CGSize {
        return CGSize(width: 25, height: 25)
    }

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

    public var annotationColor: NSColor = .currentLocationBlue {
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

    private var minPulseScale: CGFloat {
        // Just some formular found by expirimenting to make the pulse depending on the dot inset and the width
        return (self.bounds.width-self.colorDotInset*2+2)/self.bounds.width
    }

    private var outerDotLayer: CALayer?
    private var colorDotLayer: CALayer?

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: UserLocationView.defaultSize)

        self.wantsLayer = true
        self.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        self.calloutOffset = CGPoint(x: 0, y: 4)
        self.canShowCallout = true
        self.collisionMode = .circle
        self.isDraggable = true
        self.displayPriority = .required
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func rebuildLayers() {
        self.layer?.removeAllAnimations()

        self.outerDotLayer?.removeFromSuperlayer()
        self.outerDotLayer = createOuterDotLayer()

        self.colorDotLayer?.removeFromSuperlayer()
        self.colorDotLayer = createColorDotLayer()

        self.layer?.addSublayer(self.colorDotLayer!)
        self.layer?.addSublayer(self.outerDotLayer!)

        self.addPulseAnimation()
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        guard newSuperview != nil else { return }
        self.rebuildLayers()
    }

    private func createPulseAnimationGroup() -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.duration = self.pulseAnimationDuration + self.delayBetweenPulseCycles
        group.repeatCount = .infinity
        group.autoreverses = true
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: .default)

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = self.minPulseScale
        pulseAnimation.duration = self.pulseAnimationDuration

        group.animations = [pulseAnimation]
        return group
    }

    private func createOuterPulseAnimationGroup() -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.duration = self.pulseAnimationDuration + self.delayBetweenPulseCycles
        group.repeatCount = .infinity
        group.autoreverses = true
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: .default)

        let scale = self.minPulseScale
        let pulseAnimation = CABasicAnimation(keyPath: "transform")
        var tr = CATransform3DIdentity
        tr = CATransform3DTranslate(tr, self.bounds.width/2, self.bounds.height/2, 0)
        tr = CATransform3DScale(tr, scale, scale, 1)
        tr = CATransform3DTranslate(tr, -self.bounds.width/2, -self.bounds.height/2, 0)
        pulseAnimation.toValue = NSValue(caTransform3D: tr)
        pulseAnimation.duration = self.pulseAnimationDuration

        group.animations = [pulseAnimation]
        return group
    }

    private func addPulseAnimation() {
        guard self.delayBetweenPulseCycles != .infinity else { return }

        let innerPulse = self.createPulseAnimationGroup()
        let outerPulse = self.createOuterPulseAnimationGroup()
        self.colorDotLayer?.add(innerPulse, forKey: "pulse")
        self.outerDotLayer?.mask?.add(outerPulse, forKey: "pulse")
    }

    private func createOuterDotLayer() -> CALayer {
        let inset = self.colorDotInset
        let shadowRadius = 3.0
        let shadowOffsetY = 2.0

        let outerDotLayer = CALayer()
        outerDotLayer.bounds = self.bounds
        outerDotLayer.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        outerDotLayer.allowsGroupOpacity = true
        outerDotLayer.backgroundColor = self.outerColor.cgColor
        outerDotLayer.cornerRadius = self.bounds.width/2
        outerDotLayer.shadowColor = .black
        outerDotLayer.shadowOffset = CGSize(width: 0, height: shadowOffsetY)
        outerDotLayer.shadowRadius = shadowRadius
        outerDotLayer.shadowOpacity = 0.3

        // This layer cuts out the inner circle of the outer layer. This prevents the drop shadow to be drawn in the
        // inside of the outer layer. This is therefore NOT the same as setting a border with a clear fill color. A drop
        // shadow would still be seen under the inner clear fill. This is only relevant, since we want to allow
        // transparent inner and outer colors.
        var outerRect = self.bounds
        let innerDiameter = outerRect.width - inset * 2
        // Make enough room for the drop shadow
        outerRect = outerRect.insetBy(dx: -outerRect.width/2, dy: -outerRect.height/2)
        outerRect.size.width *= 2
        outerRect.size.height *= 2
        let innerRect = CGRect(x: inset, y: inset, width: innerDiameter, height: innerDiameter)
        let outerCircle = NSBezierPath(rect: outerRect)
        let innerCircle = NSBezierPath(roundedRect: innerRect,
                                       xRadius: innerRect.width * 0.5,
                                       yRadius: innerRect.height * 0.5)
        outerCircle.append(innerCircle)

        let mask = CAShapeLayer()
        mask.fillRule = .evenOdd
        mask.path = outerCircle.cgPath
        outerDotLayer.mask = mask

        outerDotLayer.shouldRasterize = true
        outerDotLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 1.0

        return outerDotLayer
    }

    private func createColorDotLayer() -> CALayer {
        let colorDotLayer = CALayer()
        let width = self.bounds.size.width - self.colorDotInset*2
        colorDotLayer.bounds = CGRect(x: 0, y: 0, width: width, height: width)
        colorDotLayer.allowsGroupOpacity = true
        colorDotLayer.backgroundColor = self.annotationColor.cgColor
        colorDotLayer.cornerRadius = width/2
        colorDotLayer.position = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        colorDotLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 1.0

        return colorDotLayer
    }
}
