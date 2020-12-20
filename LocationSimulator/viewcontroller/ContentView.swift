//
 //  ContentView.swift
 //  LocationSimulator
 //
 //  Created by David Klopp on 14.08.20.
 //  Copyright © 2020 David Klopp. All rights reserved.
 //

 import AppKit

 class ContentView: NSView {
    /// The spinner in the top right corner.
    @IBOutlet var spinnerHUD: SpinnerHUDView!

    /// The direction outer circle.
    @IBOutlet var movementControlHUD: MovementControlHUDView!

    /// The movement button.
    @IBOutlet var movementButtonHUD: MovementButtonHUDView!

    /// The container view which contains the button and the control.
    @IBOutlet var movementContainer: NSView! {
        didSet {
            // Add a rotation gesture recognizer to the movement container.
            let rotateRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(overlayRotateByGesture))
            self.movementContainer.addGestureRecognizer(rotateRecognizer)
        }
    }

    /// Show or hide the navigation controls in the lower left corner.
    public var controlsHidden: Bool {
        get { self.movementContainer.isHidden }
        set { self.movementContainer.isHidden = newValue }
    }

    /// Starting angle for the direction overlay rotation.
    private var startAngleInDegrees: Double = 0.0

    // MARK: - Gesture Recognizer

    /// Rotate the translation overlay to a specific angle given in degrees.
    func rotateOverlayTo(angleInDegrees angle: Double) {
        self.movementControlHUD.rotateOverlayTo(angleInDegrees: angle)
    }

    /// Rotate the translation overlay to a specific angle given in rad.
    func rotateOverlayTo(angleInRad angle: Double) {
        self.movementControlHUD.rotateOverlayTo(angleInRad: angle)
    }

    @objc private func overlayRotateByGesture(sender: NSRotationGestureRecognizer) {
        switch sender.state {
        case .began, .ended:
            self.startAngleInDegrees = self.movementControlHUD.currentHeadingInDegrees
        case .changed:
            let deltaAngle = Double(sender.rotation * 180 / .pi)
            self.rotateOverlayTo(angleInDegrees: self.startAngleInDegrees + deltaAngle)
        default:
            break
        }
    }

    // MARK: - Layout
    override func layout() {
        super.layout()

        // Fix bottom bar color on Big Sur.
        if #available(OSX 11.0, *) {
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor(named: "bottomBarBackground")?.cgColor
        }
    }

    // MARK: - Spinner

    /// Show an animated progress spinner in the upper right corner.
    func startSpinner() {
        self.spinnerHUD.startSpinning()
        self.spinnerHUD.isHidden = false
    }

    /// Hide and stop the progress spinner in the upper right corner.
    func stopSpinner() {
        self.spinnerHUD.stopSpinning()
        self.spinnerHUD.isHidden = true
    }

 }
