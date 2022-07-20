//
//  HUDView.swift
//  LocationSimulator2
//
//  Created by David Klopp on 17.08.20.
//

import AppKit

/// Common abstract superclass for all HUD controls.
class HUDView: NSView {
    /// Add all subviews to this view.
    var contentView: NSView {
        return self.effectView
    }

    /// Set the corner radius for this view and the effect view.
    var cornerRadius: CGFloat = 5.0 {
        didSet { self.applyCornerRadius(self.cornerRadius) }
    }

    /// Set a views background color
    var backgroundColor: NSColor {
        get {
            if let cgColor = self.layer?.backgroundColor, let color = NSColor(cgColor: cgColor) {
                return  color
            }
            return .clear
        }
        set {
            self.layer?.backgroundColor = newValue.cgColor
        }
    }

    /// The visuel effect view background
    lazy var effectView: NSVisualEffectView = {
        let effectView = NSVisualEffectView()
        effectView.blendingMode = .withinWindow
        effectView.wantsLayer = true
        return effectView
    }()

    // MARK: - Constructor

    private func setup() {
        // Round the corners of the VisuelEffectView
        self.effectView.layer?.masksToBounds = true
        self.effectView.frame = self.bounds
        self.effectView.autoresizingMask = [.height, .width]
        self.addSubview(self.effectView)

        // Prepare the layer
        self.wantsLayer = true
        self.layer?.masksToBounds = false

        // Change the effectView style.
        self.applyCornerRadius(self.cornerRadius)
        self.applyEffectViewStyle()
        self.applyDropShadow()
    }

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - layout

    /// Apply a drop shadow to the HUD.
    private func applyDropShadow() {
        if #unavailable(OSX 11.0) {
            // Add a nice drop shadow around the HUD for older macOS versions.
            let shadow = NSShadow()
            shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.3)
            shadow.shadowBlurRadius = 0.5
            shadow.shadowOffset = NSSize(width: 0.0, height: -0.5)
            self.shadow = shadow
        }
    }

    /// Change the current effectView style depending on the OS Version and dark / light mode.
    private func applyEffectViewStyle() {
        if #available(OSX 11.0, *) {
            effectView.material = .titlebar
        } else if #available(OSX 10.14, *) {
            let isDark =  NSAppearance.current.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            effectView.material = isDark ? .titlebar : .contentBackground
        } else {
            // Mac OS 10.13 support was removed.
            effectView.material = .titlebar
        }

        effectView.isEmphasized = true
        effectView.state = .active
    }

    /// Change the corner radius of the effectView and this view depending on the OS Version and dark / light mode.
    /// - Parameter radius: the new corner radius
    private func applyCornerRadius(_ radius: CGFloat) {
        self.layer?.cornerRadius = radius
        self.effectView.layer?.cornerRadius = radius

        if #unavailable(OSX 11.0) {
            // Add a thin border for older macOS systems
            self.layer?.borderColor = NSColor.separator.cgColor
            self.layer?.borderWidth = 0.5
        }
    }

    override func layout() {
        super.layout()
        // Reapply the corner radius on layout to adapt to dark mode.
        self.applyEffectViewStyle()
        self.applyCornerRadius(self.cornerRadius)
    }

}
