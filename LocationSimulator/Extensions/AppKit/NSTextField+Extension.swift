//
//  NSTextField+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 28.11.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

extension NSTextField {
    func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            self.animate(change: {
                self.stringValue = newValue
            }, interval: interval)
        } else {
            self.stringValue = newValue
        }
    }

    func setAttributedStringValue(_ newValue: NSAttributedString, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard attributedStringValue != newValue else { return }
        if animated {
            self.animate(change: {
                self.attributedStringValue = newValue
            }, interval: interval)
        } else {
            self.attributedStringValue = newValue
        }
    }

    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = interval / 2.0
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = interval / 2.0
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
}
