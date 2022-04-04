//
//  ChangeLogViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class InfoViewController: PreferenceViewControllerBase {
    override func loadView() {
        let infoField = NSTextField(frame: .zero)
        infoField.isEditable = false
        infoField.isEnabled = false
        infoField.backgroundColor = .clear
        infoField.textColor = .labelColor
        infoField.font = .labelFont(ofSize: NSFont.systemFontSize)
        infoField.alignment = .center
        infoField.isBezeled = false

        // Add the welcome text and resize the view
        let welcomeString = "WELCOME".localized
        let changelogString = "CHANGELOG".localized
        infoField.stringValue = "\n" + welcomeString + "\n" + changelogString + "\n"
        infoField.sizeToFit()

        // Add some padding to the left and right
        infoField.frame.size.width += 40

        self.view = infoField
    }
}
