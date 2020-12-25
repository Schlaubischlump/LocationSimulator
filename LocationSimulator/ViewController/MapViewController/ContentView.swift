//
 //  ContentView.swift
 //  LocationSimulator
 //
 //  Created by David Klopp on 14.08.20.
 //  Copyright © 2020 David Klopp. All rights reserved.
 //

 import AppKit

typealias ErrorIndicatorAction = () -> Void

/// This is the main content view. It includes the mapView and all the controls that overlay the mapView.
/// Since this view contains links to the interface builders main storyboard, it belongs to this viewController and
/// not to the general Views group.
 class ContentView: NSView {
    /// The spinner in the top right corner.
    @IBOutlet var spinnerHUD: SpinnerHUDView!

    /// The direction outer circle.
    @IBOutlet var movementDirectionHUD: MovementDirectionHUDView!

    /// The movement button.
    @IBOutlet var movementButtonHUD: MovementButtonHUDView!

    /// The error indicator in the lower right corner.
    @IBOutlet var errorIndicator: NSImageView! {
        didSet {
            // Add a click gesture to the view.
            let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(errorIndicatorClicked(_:)))
            self.errorIndicator.addGestureRecognizer(clickGesture)
        }
    }

    /// The label in the bottom bar which displays the total amount of meters you walked.
    @IBOutlet var totalDistanceLabel: NSTextField!

    /// The container view which contains the button and the control.
    @IBOutlet var movementContainer: NSView! {
        didSet {
            // Make the view layer backed.
            self.movementContainer.wantsLayer = true
            // Add a rotation gesture recognizer to the movement container.
            let recognizer = NSRotationGestureRecognizer(target: self, action: #selector(directionHUDRotateByGesture))
            self.movementContainer.addGestureRecognizer(recognizer)
        }
    }

    /// Show or hide the navigation controls in the lower left corner.
    public var controlsHidden: Bool {
        get { self.movementContainer.isHidden }
        set { self.movementContainer.isHidden = newValue }
    }

    /// The action to perform when the error indicator is clicked.
    public var errorIndicationAction: ErrorIndicatorAction?

    /// Starting angle for the direction overlay rotation.
    private var startAngleInDegrees: Double = 0.0

    // MARK: - Helper

    @objc private func errorIndicatorClicked(_ sender: Any) {
        // Disable the user interaction while the action is performed.
        self.errorIndicator.isEnabled = false
        self.errorIndicationAction?()
        self.errorIndicator.isEnabled = true
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        // Fix bottom bar color on Big Sur.
        if #available(OSX 11.0, *) {
            self.layer?.backgroundColor = NSColor(named: "bottomBarBackground")?.cgColor
        }
    }

    // MARK: - Gesture Recognizer

    /// Rotate the translation overlay to a specific angle given in degrees.
    public func rotateDirectionHUD(toAngleInDegrees angle: Double) {
        self.movementDirectionHUD.rotateyTo(angleInDegrees: angle)
    }

    /// Rotate the translation overlay to a specific angle given in rad.
    public func rotateDirectionHUD(toAngleInRad angle: Double) {
        self.movementDirectionHUD.rotateTo(angleInRad: angle)
    }

    @objc private func directionHUDRotateByGesture(sender: NSRotationGestureRecognizer) {
        switch sender.state {
        case .began, .ended:
            self.startAngleInDegrees = self.movementDirectionHUD.currentHeadingInDegrees
        case .changed:
            let deltaAngle = Double(sender.rotation * 180 / .pi)
            self.rotateDirectionHUD(toAngleInDegrees: self.startAngleInDegrees + deltaAngle)
        default:
            break
        }
    }

    // MARK: - Spinner

    /// Show an animated progress spinner in the upper right corner.
    public func startSpinner() {
        self.spinnerHUD.startSpinning()
        self.spinnerHUD.isHidden = false
    }

    /// Hide and stop the progress spinner in the upper right corner.
    public func stopSpinner() {
        self.spinnerHUD.stopSpinning()
        self.spinnerHUD.isHidden = true
    }

    // MARK: - Bottom bar

    /// Change the text of the total distance label.
    /// - Parameter meter: the amount of meters walked
    public func setTotalDistance(meter: Double) {
        let totalDistanceInKM = meter / 1000.0
        let labelText = NSLocalizedString("TOTAL_DISTANCE", comment: "")
        self.totalDistanceLabel.stringValue = String(format: labelText, totalDistanceInKM)
    }

    /// Show the warning triangle in the lower right corner.
    public func showErrorInidcator() {
        self.errorIndicator.isHidden = false
    }

    /// Hide the warning triangle in the lower right corner.
    public func hideErrorInidcator() {
        self.errorIndicator.isHidden = true
    }
 }
