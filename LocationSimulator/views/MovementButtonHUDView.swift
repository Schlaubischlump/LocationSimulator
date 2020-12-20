//
//  MovementButtonHUD.swift
//  LocationSimulator2
//
//  Created by David Klopp on 17.08.20.
//

import AppKit

typealias MovementButtonClickAction = () -> Void

typealias MovementButtonPressAction = () -> Void

/// The movement button which can be clicked or long pressed to trigger actions.
class MovementButtonHUDView: HUDView, NSGestureRecognizerDelegate {
    /// Highlight the movement button by applying a blue tint
    var highlight: Bool = false {
        didSet {
            self.effectView.isHidden = highlight
            self.backgroundColor = highlight ? .highlight : .clear
            self.imageView.tint(color: highlight ? .white : .highlight)
        }
    }

    /// Action to perform on a long press.
    var longPressAction: MovementButtonPressAction?

    /// Action to perform on a click.
    var clickAction: MovementButtonClickAction?

    /// Image view inside the button
    private let imageView = NSImageView(image: .moveImage)

    // MARK: - Constructor

    private func setup() {
        // Add a long press gesture recognizer to simulate a toogle state
        let pressGesture = NSPressGestureRecognizer(target: self, action: #selector(self.buttonPressed))
        pressGesture.buttonMask = 0x1
        pressGesture.minimumPressDuration = 0.5
        pressGesture.allowableMovement = 0
        pressGesture.delegate = self
        self.addGestureRecognizer(pressGesture)

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(self.buttonClicked))
        clickGesture.buttonMask = 0x1
        clickGesture.numberOfClicksRequired = 1
        clickGesture.numberOfTouchesRequired = 1
        clickGesture.delegate = self
        self.addGestureRecognizer(clickGesture)

        // Add the imageView to the view hierachy
        self.imageView.tint(color: .highlight)
        self.imageView.frame = self.bounds
        self.imageView.autoresizingMask = [.width, .height]
        self.addSubview(self.imageView)
    }

    override init() {
        super.init()
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - layout
    override func layout() {
        super.layout()
        self.cornerRadius = self.frame.width/2.0
    }

    // MARK: - NSGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return false
    }

    // MARK: - Callback

    /// Called on a long press.
    @objc private func buttonPressed(sender: NSPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.highlight = !self.highlight
            self.longPressAction?()
        case .failed, .cancelled:
            self.highlight = false
        default:
            break
        }
    }

    private var material: Int = 0

    /// Called on a click.
    @objc private func buttonClicked(sender: NSPressGestureRecognizer) {

        print("Material: ", self.material)
        self.effectView.material = NSVisualEffectView.Material(rawValue: self.material)!
        self.effectView.isEmphasized = !self.effectView.isEmphasized
        if self.effectView.isEmphasized {
            self.material = (self.material + 1) % 30
        }

        /*if sender.state == .ended {
            self.highlight = !self.highlight
            self.clickAction?()
            // Keep the button highlighted for a couple of seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.035, execute: {
                self.highlight = false
            })
        }*/
    }
}
