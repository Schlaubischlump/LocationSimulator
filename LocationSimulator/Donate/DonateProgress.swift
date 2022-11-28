//
//  DonateProgress.swift
//  LocationSimulator
//
//  Created by David Klopp on 27.11.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import Cocoa

enum Kind {
    case primary
    case secondary
}

enum Side {
    case left
    case right
}

private func createLabel(kind: Kind, side: Side) -> NSTextField {
    let label = NSTextField()
    label.drawsBackground = false
    label.isBezeled = false
    label.isEditable = false
    label.isSelectable = false
    label.isBordered = false

    switch kind {
    case .primary:
        label.textColor = .labelColor
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 6.0)
    case .secondary:
        label.textColor = .secondaryLabelColor
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
    }

    if kind == .primary && side == .right {
        label.textColor = kDonateTextBlue
    }

    switch side {
    case .right: label.alignment = .right
    case .left:  label.alignment = .left
    }
    return label
}

class DonateProgress: NSView {
    var currencySymbol: String = "€"

    var hasAmount: Double = 0 {
        didSet {
            self.hasAmountLabel.setStringValue("\(self.hasAmount)\(self.currencySymbol)", animated: true)
            self.updatePercentage()
        }
    }

    var goalAmount: Double = 100 {
        didSet {
            let text = "OF".localized + " \(self.goalAmount)\(self.currencySymbol)"
            self.goalAmountLabel.setStringValue(text, animated: true)
            self.updatePercentage()
        }
    }

    var goal: String = "Goal" {
        didSet {
            self.goalLabel.setStringValue(self.goal, animated: true)
        }
    }

    private(set) var percentage: Double = 0 {
        didSet {
            guard abs(oldValue - self.percentage) >= 0.01 else { return }
            self.progressBar.doubleValue = Double(self.percentage)
            self.percentageLabel.setStringValue("\(Int(self.percentage * 100))%", animated: true)
        }
    }

    private lazy var hasAmountLabel: NSTextField = createLabel(kind: .primary, side: .left)
    private lazy var goalAmountLabel: NSTextField = createLabel(kind: .secondary, side: .left)
    private lazy var percentageLabel: NSTextField = createLabel(kind: .primary, side: .right)
    private lazy var goalLabel: NSTextField = createLabel(kind: .secondary, side: .right)
    private lazy var progressBar: NSProgressIndicator = {
        let progressBar = NSProgressIndicator()
        progressBar.style = .bar
        progressBar.isIndeterminate = false
        progressBar.usesThreadedAnimation = true
        progressBar.minValue = 0.0
        progressBar.maxValue = 1.0
        return progressBar
    }()

    private(set) var isAnimating: Bool = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePercentage() {
        self.percentage = self.hasAmount/self.goalAmount
    }

    func setup() {
        self.addSubview(self.progressBar)
        self.addSubview(self.hasAmountLabel)
        self.addSubview(self.goalAmountLabel)
        self.addSubview(self.percentageLabel)
        self.addSubview(self.goalLabel)
    }

    func sizeToFit() {
        self.layout()
    }

    func startWaitAnimation() {
        guard !self.isAnimating else { return }
        self.isAnimating = true
        self.progressBar.doubleValue = 0
        self.progressBar.isIndeterminate = true
        self.progressBar.startAnimation(nil)
    }

    func stopWaitAnimation() {
        guard self.isAnimating else { return }
        self.isAnimating = false
        self.progressBar.stopAnimation(nil)
        self.progressBar.isIndeterminate = false
    }

    override func layout() {
        super.layout()

        let labelWidth = self.bounds.width/2

        self.hasAmountLabel.sizeToFit()
        self.goalAmountLabel.sizeToFit()
        self.percentageLabel.sizeToFit()
        self.goalLabel.sizeToFit()

        let firstRowHeight = max(self.hasAmountLabel.frame.height, self.percentageLabel.frame.height)
        let secondaryRowHeight = max(self.goalAmountLabel.frame.height, self.goalLabel.frame.height)

        self.progressBar.sizeToFit()
        self.progressBar.frame.size.width = self.bounds.width

        let yOffSecondRow = self.progressBar.frame.maxY
        let yOffFirstRow = yOffSecondRow + secondaryRowHeight

        self.hasAmountLabel.frame = CGRect(x: 0, y: yOffFirstRow, width: labelWidth, height: firstRowHeight)
        self.percentageLabel.frame = CGRect(x: labelWidth, y: yOffFirstRow, width: labelWidth, height: firstRowHeight)
        self.goalAmountLabel.frame = CGRect(x: 0, y: yOffSecondRow, width: labelWidth, height: secondaryRowHeight)
        self.goalLabel.frame = CGRect(x: labelWidth, y: yOffSecondRow, width: labelWidth, height: secondaryRowHeight)

        self.frame.size.height = max(self.hasAmountLabel.frame.maxY, self.percentageLabel.frame.maxY)
    }
}
