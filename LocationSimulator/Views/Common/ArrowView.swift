//
//  ArrowView.swift
//  LocationSimulator
//
//  Created by David Klopp on 01.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit

private extension NSColor {
    static var arrowColor: NSColor = NSColor(name: nil) { $0.isDark ? .controlAccentColor : .gray }
    static var arrowActiveColor = NSColor(name: nil) { $0.isDark ? .controlAccentColor : .black }
    static var arrowDisabledColor: NSColor = NSColor(name: nil) {
        $0.isDark ? .controlAccentColor.withAlphaComponent(0.1) : .separator
    }
}

final internal class ArrowView: NSView {
    internal enum Direction {
        case left
        case right
    }

    /// The direction the arrow is pointing at.
    var direction: Direction = .left {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    /// The width of the arrow lines.
    var lineWidth: CGFloat = 2.0

    /// The action to perform when the arrow is clicked
    var action: (() -> Void)?

    /// True if the arrow is currently active
    private var isActive: Bool = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    var isUserInteractionEnabled: Bool = true {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    /// The maximum size the arrow on the left or right side can occupy.
    private var maximumArrowSize: CGSize {
        return CGSize(width: 14, height: 50)
    }

    convenience init(direction: Direction) {
        self.init(frame: .zero)
        self.direction = direction
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(self.onClick(_:)))
        recognizer.delaysPrimaryMouseButtonEvents = false
        recognizer.numberOfClicksRequired = 1
        recognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(recognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let height = min(rect.height, self.maximumArrowSize.height)
        let width = min(rect.width, self.maximumArrowSize.width)
        let originY = (rect.height - height)/2
        let originX = (rect.width - width)/2

        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        if self.direction == .left {
            path.move(to: CGPoint(x: rect.width - originX, y: originY))
            path.line(to: CGPoint(x: originX, y: originY + height/2))
            path.line(to: CGPoint(x: rect.width - originX, y: originY + height))
        } else {
            path.move(to: CGPoint(x: originX, y: originY))
            path.line(to: CGPoint(x: rect.width - originX, y: originY + height/2))
            path.line(to: CGPoint(x: originX, y: originY + height))
        }

        if self.isActive {
            NSColor.arrowActiveColor.setStroke()
            path.lineWidth = self.lineWidth + 1
        } else if self.isUserInteractionEnabled {
            NSColor.arrowColor.setStroke()
            path.lineWidth = self.lineWidth
        } else {
            NSColor.arrowDisabledColor.setStroke()
            path.lineWidth = self.lineWidth
        }

        path.stroke()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return self.isUserInteractionEnabled ? super.hitTest(point) : nil
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.isActive = true
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        self.isActive = false
    }

    @objc func onClick(_ recognizer: NSClickGestureRecognizer) {
        if case .ended = recognizer.state {
            self.action?()
        }
    }
}
