//
//  AutoCompletePopover.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class AutoCompletePopover: NSPanel {
    private var localMouseDownEventMonitor: Any?

    private var lostFocusObserver: Any?

    init(contentViewController: NSViewController) {
        super.init(contentRect: .zero, styleMask: [.borderless], backing: NSWindow.BackingStoreType.buffered, defer: false)

        self.contentViewController = contentViewController

        // add an effectview as subview to the contentView
        let effectView = NSVisualEffectView(frame: self.contentView!.bounds)
        effectView.autoresizingMask = [.height, .width]
        effectView.appearance = self.appearance
        effectView.blendingMode = .behindWindow

        // insert the effectView as the lowest view inside the contentView view hierachy
        let subviews = self.contentView?.subviews
        subviews?.forEach { $0.removeFromSuperview() }
        self.contentView?.addSubview(effectView)
        subviews?.forEach { contentView?.addSubview($0) }

        // round the contentViews corners
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 5.0

        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.isFloatingPanel = true
    }

    override var canBecomeKey: Bool {
        // prevent the window from steeling the focus of our main window
        return false
    }

    override func setContentSize(_ size: NSSize) {
        // keep the top left corner when changing the content size
        let topLeft: CGPoint = CGPoint(x: self.frame.minX, y: self.frame.maxY)
        super.setContentSize(size)
        self.setFrameTopLeftPoint(topLeft)
    }

    func show(relativeTo positioningRect: NSRect, of positioningView: NSView) {
        guard let window = positioningView.window else {
            return
        }

        // position window below the positioningView
        let winFrame: NSRect = window.frame
        let posFrame: NSRect = positioningView.convert(positioningView.frame, to: window.contentView)
        var popupOrigin: CGPoint = self.frame.origin

        popupOrigin.x = winFrame.minX + posFrame.minX + positioningRect.minX
        popupOrigin.y = winFrame.minY + posFrame.maxY - positioningRect.maxY - self.frame.height - 2.0
        self.setFrameOrigin(popupOrigin)

        window.addChildWindow(self, ordered: .above)

        // catch all click events outside the window to dismiss it
        self.localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [unowned self] (event) -> NSEvent? in

            // make sure the event has a window
            guard let win = event.window else {
                return event
            }

            // if the window was clicked outside its toolbar then dismiss the popup
            if win != self && win.contentView?.hitTest(event.locationInWindow) != nil {
                self.close()
            }
            return event
        }

        // if the window looses focus we need to dismiss the suggestion window as well
        self.lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: nil) { [unowned self] notification  in
                self.close()
        }
    }

    func cleanupMonitoring() {
        if let eventMonitor = self.localMouseDownEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.localMouseDownEventMonitor = nil
        }

        if let focusOberserver = self.lostFocusObserver {
            NotificationCenter.default.removeObserver(focusOberserver)
            self.lostFocusObserver = nil
        }
    }

    override func close() {
        self.cleanupMonitoring()
        super.close()
    }

    deinit {
        self.cleanupMonitoring()
    }
}
