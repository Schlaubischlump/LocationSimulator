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
        label.textColor = kDonateYellow
    }

    switch side {
    case .right: label.alignment = .right
    case .left:  label.alignment = .left
    }
    return label
}

class DonateProgress: NSView {
    var currencySymbol: String = "€"

    var hasAmount: Float? {
        didSet {
            guard let hasAmount = self.hasAmount, oldValue != hasAmount else { return }
            self.hasAmountLabel.setStringValue("\(hasAmount)\(self.currencySymbol)", animated: true)
            self.updatePercentage()
        }
    }

    var goalAmount: Float? {
        didSet {
            guard let goalAmount = self.goalAmount, oldValue != self.goalAmount else { return }
            let text = "OF".localized + " \(goalAmount)\(self.currencySymbol)"
            self.goalAmountLabel.setStringValue(text, animated: true)
            self.updatePercentage()
        }
    }

    var goal: String = "Goal" {
        didSet {
            guard oldValue != self.goal else { return }
            self.goalLabel.setStringValue(self.goal, animated: true)
        }
    }

    private(set) var percentage: Float = 0 {
        didSet {
            guard abs(oldValue - self.percentage) >= 0.01 else { return }
            self.progressBar.setProgress(self.percentage, animated: true)
            self.percentageLabel.setStringValue("\(Int(self.percentage * 100))%", animated: true)
        }
    }

    private lazy var hasAmountLabel: NSTextField = createLabel(kind: .primary, side: .left)
    private lazy var goalAmountLabel: NSTextField = createLabel(kind: .secondary, side: .left)
    private lazy var percentageLabel: NSTextField = createLabel(kind: .primary, side: .right)
    private lazy var goalLabel: NSTextField = createLabel(kind: .secondary, side: .right)
    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.progress = 0
        progressBar.progressTintColor = kDonateYellow
        return progressBar
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePercentage() {
        guard let hasAmount = self.hasAmount, let goalAmount = self.goalAmount else { return }
        self.percentage = hasAmount/goalAmount
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

    override func layout() {
        super.layout()

        let spaceY: CGFloat = 10
        let labelWidth = self.bounds.width/2

        self.hasAmountLabel.sizeToFit()
        self.goalAmountLabel.sizeToFit()
        self.percentageLabel.sizeToFit()
        self.goalLabel.sizeToFit()

        let firstRowHeight = max(self.hasAmountLabel.frame.height, self.percentageLabel.frame.height)
        let secondaryRowHeight = max(self.goalAmountLabel.frame.height, self.goalLabel.frame.height)

        self.progressBar.frame.size = CGSize(width: self.bounds.width, height: 12)

        let yOffSecondRow = self.progressBar.frame.maxY + spaceY
        let yOffFirstRow = yOffSecondRow + secondaryRowHeight

        self.hasAmountLabel.frame = CGRect(x: 0, y: yOffFirstRow, width: labelWidth, height: firstRowHeight)
        self.percentageLabel.frame = CGRect(x: labelWidth, y: yOffFirstRow, width: labelWidth, height: firstRowHeight)
        self.goalAmountLabel.frame = CGRect(x: 0, y: yOffSecondRow, width: labelWidth, height: secondaryRowHeight)
        self.goalLabel.frame = CGRect(x: labelWidth, y: yOffSecondRow, width: labelWidth, height: secondaryRowHeight)

        self.frame.size.height = max(self.hasAmountLabel.frame.maxY, self.percentageLabel.frame.maxY)
    }
}
