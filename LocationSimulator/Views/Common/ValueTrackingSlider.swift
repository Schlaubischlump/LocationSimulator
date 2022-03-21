//
//  ValueTrackingSlider.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class ValueTrackingSliderCell: NSSliderCell {
    private var slider: ValueTrackingSlider? {
        return self.controlView as? ValueTrackingSlider
    }

    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        let result = super.startTracking(at: startPoint, in: controlView)
        self.slider?.startTracking(at: startPoint, in: controlView)
        return result
    }

    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint,
                                   in controlView: NSView) -> Bool {
        let result = super.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
        self.slider?.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
        return result
    }

    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView,
                               mouseIsUp flag: Bool) {
        super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
        self.slider?.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
    }
}

class ValueTrackingSlider: NSSlider {

    /// A format handler to convert the current double value to an information string to display
    public var formatHandler: ((Double) -> String)?

    /// The popover that display the current slider value
    private lazy var informationPopover: NSPopover = {
        let controller = NSViewController()

        let label = NSTextField()
        label.drawsBackground = false
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 40, height: 18)
        label.stringValue = ""
        controller.view = label

        let popover = NSPopover()
        popover.contentViewController = controller
        popover.contentSize = controller.view.frame.size

        popover.behavior = .applicationDefined
        popover.animates = true

        return popover
    }()

    private var dismissPopoverTimer: Timer?

    private var showPopoverTimer: Timer?

    // MARK: - Scrollwheel

    private var _isVertical: Bool {
        if #available(macOS 10.12, *) {
            return self.isVertical
        }
        // isVertical is an NSInteger in versions before 10.12
        return self.value(forKey: "isVertical") as? NSInteger == 1
    }

    /// Allow changing the value with the scroll wheel
    override func scrollWheel(with event: NSEvent) {
        guard self.isEnabled else { return }

        let range = self.maxValue - self.minValue
        var delta = 0.0

        // Allow horizontal scrolling on horizontal and circular sliders
        if _isVertical && self.sliderType == .linear {
            delta = Double(event.deltaY)
        } else if self.userInterfaceLayoutDirection == .rightToLeft {
            delta = Double(event.deltaY + event.deltaX)
        } else {
            delta = Double(event.deltaY - event.deltaX)
        }

        // Natural scrolling
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }

        let increment = range * delta / 100

        self.doubleValue += increment
        self.sendAction(self.action, to: self.target)

        self.showInformationPopover()

        self.dismissPopoverTimer?.invalidate()
        self.dismissPopoverTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                                        selector: #selector(self.dismissInformationPopover),
                                                        userInfo: nil, repeats: false)
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        self.showPopoverTimer?.invalidate()
        self.showPopoverTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self,
                                                     selector: #selector(self.showInformationPopover),
                                                     userInfo: nil, repeats: false)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.dismissInformationPopover()
    }

    // MARK: - Popover

    /// Show or update the information popover. The arrow is repositioned above the knob if you call this function and
    /// the slider value information text is updated. The contentSize is updated to fit the information text.
    @objc public func showInformationPopover() {
        if let label = self.informationPopover.contentViewController?.view as? NSTextField {
            let text = self.formatHandler?(self.doubleValue) ?? ""
            let font = label.font ?? NSFont.systemFont(ofSize: NSFont.labelFontSize)

            label.stringValue = text
            label.frame.size.width = text.fittingWidth(forFont: font) + 10
            self.informationPopover.contentSize = label.frame.size
        }

        // Default behaviour: Just show the popup in the middle of the slider. This is hopefully never the case.
        var rect = self.bounds

        if let knobRect = (self.cell as? NSSliderCell)?.knobRect(flipped: false) {
            // If you click inside the slider, the knobRect is not yet upadted. This formular calculates the real knob
            // position so that the popup appears below the target position.
            let percentage = (self.doubleValue - self.minValue) / (self.maxValue - self.minValue)
            rect = CGRect(x: (self.frame.width - knobRect.width) * percentage,
                              y: knobRect.origin.y, width: knobRect.width, height: knobRect.height)
        }

        self.informationPopover.show(relativeTo: rect, of: self, preferredEdge: NSRectEdge.maxY)
    }

    /// Dismiss the information popup
    @objc public func dismissInformationPopover() {
        self.informationPopover.close()

        self.showPopoverTimer?.invalidate()
        self.showPopoverTimer = nil

        self.dismissPopoverTimer?.invalidate()
        self.dismissPopoverTimer = nil
    }

    // MARK: - Tracking

    fileprivate func startTracking(at startPoint: NSPoint, in controlView: NSView) {
        // Show the popup
        self.showInformationPopover()
    }

    fileprivate func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) {
        // Update the arrow position to be above the knob
        self.showInformationPopover()
    }

    fileprivate func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView,
                                  mouseIsUp flag: Bool) {
        // Dismiss the popup
        self.dismissInformationPopover()
    }
}
