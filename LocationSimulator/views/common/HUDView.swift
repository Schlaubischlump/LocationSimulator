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

    var cornerRadius: CGFloat {
        get { return self.effectView.layer?.cornerRadius ?? 0}
        set {
            self.layer?.cornerRadius = newValue
            self.effectView.layer?.cornerRadius = newValue
        }
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
        effectView.material = .titlebar
        effectView.isEmphasized = true
        effectView.state = .active
        effectView.wantsLayer = true
        return effectView
    }()

    // MARK: - Constructor

    private func setup() {
        // Round the corners of the VisuelEffectView
        self.effectView.layer?.masksToBounds = true
        self.effectView.layer?.cornerRadius = 5.0
        self.effectView.frame = self.bounds
        self.effectView.autoresizingMask = [.height, .width]
        //self.effectView.layer.borderWidth = 0.5
        //self.effectView.layer.borderColor = UIColor(named: "borderColor")!.cgColor

        self.addSubview(self.effectView)
    }

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
}
