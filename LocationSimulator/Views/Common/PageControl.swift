//
//  PageControle.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import AppKit

let kFillAnimationDuration = 0.04
let kDotBorderWidth = 1.0
let kDotLength = 8.0
let kDotMargin = 12.0

public class PageControl: NSView {
    /// The current page, shown by the page control as a white dot.
    public var currentPage: Int = 0 {
        didSet(oldValue) {
            self.currentPage = max(0, min(self.currentPage, self.numberOfPages - 1))
            self.updateCurrentPage(oldValue, newPageIndex: self.currentPage)
        }
    }

    /// Click action.
    public var action: ((Int) -> Void)?

    /// The number of pages the receiver shows (as dots).
    public var numberOfPages: Int = 0
    /// A Boolean value that controls whether the page control is hidden when there is only one page.
    public var hidesForSinglePage: Bool = true
    /// The tint color to apply to the page indicator.
    public var pageIndicatorTintColor: NSColor = .darkGray
    /// The tint color to apply to the current page indicator.
    public var currentPageIndicatorTintColor: NSColor = .white

    private var dotLayers: [CAShapeLayer] = []

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(clickInside(recognizer:)))
        clickGesture.delaysPrimaryMouseButtonEvents = false
        clickGesture.numberOfClicksRequired = 1
        clickGesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(clickGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func marginX(inRect rect: CGRect) -> CGFloat {
        let dotWidthSum = kDotLength * CGFloat(self.numberOfPages)
        let marginWidthSum = kDotMargin * CGFloat((self.numberOfPages - 1))
        let minWidth = dotWidthSum + marginWidthSum
        return (rect.width - minWidth) / 2
    }

    public override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)

        let marginX = self.marginX(inRect: dirtyRect)

        self.wantsLayer = true
        self.dotLayers.forEach { $0.removeFromSuperlayer() }
        self.dotLayers = []

        if self.numberOfPages == 1 && self.hidesForSinglePage {
            return
        }

        (0..<self.numberOfPages).forEach { i in
            let x = marginX + (kDotLength + kDotMargin) * CGFloat(i)
            let y = (dirtyRect.height - kDotLength) / 2
            let rect = CGRect(x: x, y: y, width: kDotLength, height: kDotLength)
            let cgPath = CGMutablePath()
            cgPath.addEllipse(in: rect)

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = cgPath

            if i == self.currentPage {
                shapeLayer.fillColor = self.currentPageIndicatorTintColor.cgColor
            } else {
                shapeLayer.fillColor = self.pageIndicatorTintColor.cgColor
            }

            self.layer?.addSublayer(shapeLayer)
            self.dotLayers.append(shapeLayer)
        }
    }

    private func updateCurrentPage(_ oldPageIndex: Int, newPageIndex: Int) {
        guard oldPageIndex != newPageIndex else {
            return
        }

        let oldPageAnimation = makeFillColorAnimation(with: self.pageIndicatorTintColor)
        self.dotLayers[oldPageIndex].add(oldPageAnimation, forKey: "oldPageAnimation")
        let newPageAnimation = makeFillColorAnimation(with: self.currentPageIndicatorTintColor)
        self.dotLayers[newPageIndex].add(newPageAnimation, forKey: "newPageAnimation")
    }

    private func makeFillColorAnimation(with color: NSColor) -> CABasicAnimation {
        let fillColorAnimation: CABasicAnimation = CABasicAnimation(keyPath: "fillColor")
        fillColorAnimation.toValue = color.cgColor
        fillColorAnimation.duration = kFillAnimationDuration
        fillColorAnimation.fillMode = .forwards
        fillColorAnimation.isRemovedOnCompletion = false
        return fillColorAnimation
    }

    @objc func clickInside(recognizer: NSClickGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }

        let marginX = self.marginX(inRect: self.frame)
        let loc = recognizer.location(in: self)
        let pageIndex = Int((loc.x - marginX) / (kDotLength + kDotMargin))
        if pageIndex >= 0 && pageIndex < self.numberOfPages {
            self.currentPage = pageIndex
            self.action?(pageIndex)
        }
    }
}
