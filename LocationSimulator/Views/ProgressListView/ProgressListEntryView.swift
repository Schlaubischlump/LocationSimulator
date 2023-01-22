//
//  ProgressListEntryView.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import AppKit

class ProgressEntryView: NSTableCellView {
    private let progressBar = ProgressBar()

    private let progressSpinner: NSProgressIndicator = {
        let spinner = NSProgressIndicator()
        spinner.isIndeterminate = true
        spinner.style = .spinning
        return spinner
    }()

    private var padding = CGPoint(x: 10.0, y: 15.0)
    private var spacing = CGPoint(x: 5.0, y: 10.0)

    internal var task: ProgressTask?

    var progressText: ((Float) -> (String))? {
        didSet { self.setProgress(self.progress, animated: true) }
    }
    var progress: Float {
        get { return self.progressBar.progress }
        set(newValue) { self.setProgress(newValue, animated: true) }
    }

    func setProgress(_ progress: Float, animated: Bool) {
        self.progressBar.setProgress(progress, animated: animated)
        self.label.stringValue = self.progressText?(progress) ?? ""
    }

    func startSpinner() {
        self.progressSpinner.startAnimation(nil)
    }

    func stopSpinner() {
        self.progressSpinner.startAnimation(nil)
    }

    var showSpinner: Bool = false {
        didSet {
            self.progressSpinner.isHidden = !self.showSpinner
            self.progressSpinner.stopAnimation(nil)
            self.layout()
        }
    }

    var showProgress: Bool = false {
        didSet {
            self.progressBar.isHidden = !self.showProgress
            self.layout()
        }
    }

    private let label: NSTextField = {
        let label = NSTextField()
        label.drawsBackground = false
        label.isEditable = false
        label.isBezeled = false
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.textColor = .labelColor
        label.backgroundColor = .controlColor
        label.alignment = .natural
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: label.controlSize))
        label.lineBreakMode = .byClipping
        return label
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.addSubview(self.progressSpinner)
        self.addSubview(self.label)
        self.addSubview(self.progressBar)

        self.progressBar.trackTintColor = NSColor(name: nil) { appearance in
            // TODO: How does this look on catalina ?
            let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let colorValue = isDarkMode ? 0.28 : 0.98
            return NSColor(red: colorValue, green: colorValue, blue: colorValue, alpha: 1.0)
        }
    }

    func sizeToFit() {
        self.layout()
        self.frame.size.height = self.label.frame.maxY + self.padding.y
    }

    override func layout() {
        super.layout()

        let width = self.frame.width
        let progressHeight = self.showProgress ? 10.0 : 0.0

        if self.showProgress {
            self.progressBar.frame.origin.y = self.padding.y
            self.progressBar.frame.size = CGSize(width: width, height: progressHeight)
        }

        self.label.sizeToFit()
        let labelHeight = self.label.frame.height
        self.label.frame.size.width = width
        self.label.frame.origin.y = self.padding.y + progressHeight + self.spacing.y

        if self.showSpinner {
            self.label.frame.origin.x = labelHeight + self.spacing.x
            self.progressSpinner.frame.size = CGSize(width: labelHeight, height: labelHeight)
            self.progressSpinner.frame.origin.y = self.padding.y + progressHeight + self.spacing.y
        }
    }
}
