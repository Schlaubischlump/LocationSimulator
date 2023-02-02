//
//  OnboardPageViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import AppKit

class OnboardPageViewController: NSViewController {
    /// The inset to not overlap with control elements
    var contentInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            self.doLayout()
        }
    }

    /// The main content view.
    lazy var contentView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 10.0
        stackView.alignment = .centerX
        return stackView
    }()

    override func loadView() {
        self.view = NSView()
        self.view.addSubview(self.contentView)
        self.setup()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        self.doLayout()
    }

    /// Put any layout code here
    func doLayout() {
        let insetFrame = self.view.bounds.inset(by: self.contentInset)
        self.contentView.frame = insetFrame
    }

    /// Do any additional setup such as adding views here.
    func setup() {

    }

    private func createLabel(text: String) -> NSTextField {
        let textField = NSTextField(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        textField.drawsBackground = false
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.textColor = .secondaryLabelColor
        textField.alignment = .center
        textField.backgroundColor = .clear
        textField.stringValue = text
        return textField
    }

    func createHeaderLabel(text: String) -> NSTextField {
        let textField = self.createLabel(text: text)
        textField.maximumNumberOfLines = 1
        textField.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 4.0)
        return textField
    }

    func createMessageLabel(text: String) -> NSTextField {
        let textField = self.createLabel(text: text)
        textField.maximumNumberOfLines = 3
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)
        return textField
    }
}
