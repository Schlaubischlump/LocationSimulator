//
//  GeneralTabWindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 29.10.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class GeneralViewController: NSViewController {
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
        infoField.stringValue = "\n" + NSLocalizedString("WELCOME", comment: "") + "\n"
        infoField.sizeToFit()

        // Add some padding to the left and right
        infoField.frame.size.width += 40

        self.view = infoField
    }
}
