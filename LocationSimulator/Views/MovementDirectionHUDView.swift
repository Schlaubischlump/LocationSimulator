//
//  MovementDirectionHUDView.swift
//  LocationSimulator2
//
//  Created by David Klopp on 17.08.20.
//

import AppKit

typealias MovementControlAction = () -> Void

/// Percentage of the inner circle cutout given in percentage of this views width.
/// E.g a value of 0.5 means the cutout takes up 50% of the views width.
private let kInnerCircleSizeInPercent: CGFloat = 0.58

/// The movement control which is used to adjust the heading.
class MovementDirectionHUDView: HUDView {
    /// The currect heading in degrees of the direction overlay
    public private(set) var currentHeadingInDegrees: Double = 0

    /// Direction controls overlaying the outer circle
    private let directionOverlay = NSImageView(image: .controlsImage)

    /// Callback when the heading changes.
    var headingChangedAction: MovementControlAction?

    // MARK: - Constructor

    private func setup() {
        // Add the arrow + direction overlay to the outer circle
        self.contentView.addSubview(self.directionOverlay)

        // Add all necessary gesture recognizer to rotate the overlay
        // Install Pan (Click + Move) + Tap recognizer
        let tapRecognizer = NSClickGestureRecognizer(target: self, action: #selector(rotateByTouch))
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(rotateByTouch))

        self.directionOverlay.addGestureRecognizer(tapRecognizer)
        self.directionOverlay.addGestureRecognizer(panGesture)

        // I'm not a fan of autolayout, but otherwise the rotation will break.
        self.directionOverlay.frame = self.bounds
        self.directionOverlay.autoresizingMask = [.width, .height]
    }

    override init() {
        super.init()
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - Gesture Recognizer

    @objc private func rotateByTouch(sender: NSGestureRecognizer) {
        guard sender.state == .changed || sender.state == .ended else { return }

        // We need to use self here, not the overlay, because the overlay rotates.
        let loc = sender.location(in: self)
        let deltaX = loc.x - self.frame.width / 2
        let deltaY = loc.y - self.frame.height / 2
        self.rotateTo(angleInRad: Double(atan2(-deltaX, deltaY)))
    }

    // MARK: - Rotate overlay

    /// Rotate the translation overlay to a specific angle given in degree.
    func rotateyTo(angleInDegrees angle: Double) {
        self.directionOverlay.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))
        // Normalize all values to be between 0 and 360
        let angle = angle.truncatingRemainder(dividingBy: 360)
        self.currentHeadingInDegrees = angle < 0 ? 360 + angle : angle

        let transform = CGAffineTransform(rotationAngle: CGFloat(self.currentHeadingInDegrees) * .pi / 180.0)
        self.directionOverlay.layer?.setAffineTransform(transform)

        // Call the `heading changed` callback after rotating the view.
        self.headingChangedAction?()
    }

    /// Rotate the translation overlay to a specific angle given in rad.
    func rotateTo(angleInRad angle: Double) {
        self.rotateyTo(angleInDegrees: angle * 180.0 / .pi)
    }

    // MARK: - Layout
    override func layout() {
        super.layout()

        // Cutout a hole for the inner button
        self.applyCircularCutoutMask()
    }

    /// Round the corners of the view and cutout a round hole in the middle.
    private func applyCircularCutoutMask() {
        // Round the outer corners.
        self.cornerRadius = self.effectView.frame.width/2.0

        // Cutout a hole from the middle.
        let bounds = self.effectView.bounds

        // We want the inner cutout to be 50% the size of the parent view.
        let outerbezierPath = NSBezierPath(roundedRect: bounds, xRadius: 0, yRadius: 0)
        let size = bounds.width*kInnerCircleSizeInPercent
        let rect = CGRect(x: (bounds.width-size)/2.0, y: (bounds.width-size)/2.0, width: size, height: size)
        let innerCirclepath = NSBezierPath(roundedRect: rect, xRadius: rect.width/2, yRadius: rect.height/2)
        outerbezierPath.append(innerCirclepath)
        outerbezierPath.windingRule = .evenOdd

        let fillLayer = CAShapeLayer()
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = NSColor.black.cgColor
        fillLayer.path = outerbezierPath.cgPath

        self.effectView.layer?.mask = fillLayer
    }
}
