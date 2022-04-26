//
//  ChangeLogViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kLastAppVersion: String = "com.schlaubischlump.locationsimulator.lastappversion"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var lastAppVersion: String? {
        get { return self.string(forKey: kLastAppVersion) }
        set { self.setValue(newValue, forKey: kLastAppVersion) }
    }

    /// Register the default NSUserDefault values.
    func registerInfoDefaultValues() {
        // Nothing to do here yet, since nil is a valid lastAppVersion value
    }
}

class InfoViewController: PreferenceViewControllerBase {
    override func loadView() {
        let padX = 10.0
        let padY = 10.0
        let spacingY = 15.0

        // Setup donate button
        let donateButton = DonateButton()
        donateButton.title = "DONATE_BUTTON".localized
        donateButton.target = self
        donateButton.action = #selector(openDonateWindow(_:))
        donateButton.frame.origin.y = padY

        // Setup info field
        let infoField = NSTextField(frame: .zero)
        infoField.isEditable = false
        infoField.isEnabled = false
        infoField.drawsBackground = false
        infoField.textColor = .secondaryLabelColor
        infoField.font = .labelFont(ofSize: NSFont.systemFontSize)
        infoField.alignment = .center
        infoField.isBezeled = false
        infoField.preferredMaxLayoutWidth = kMaxPreferenceViewWidth - padX*2

        infoField.stringValue = "WELCOME".localized
        infoField.frame.size = infoField.fittingSize
        infoField.frame.origin.x = padX
        infoField.frame.origin.y = donateButton.frame.maxY + spacingY

        donateButton.frame.origin.x = (infoField.frame.width - donateButton.frame.width)/2

        // Container
        let container = NSView()
        container.addSubview(infoField)
        container.addSubview(donateButton)
        container.frame.size.width = infoField.frame.width + padX*2
        container.frame.size.height = infoField.frame.maxY + padY*2

        self.view = container
    }

    @objc private func openDonateWindow(_ sender: NSButton) {
        // FIXME: This should work.... but it doesn't
        // self.performSegue(withIdentifier: "ShowDonateWindow", sender: nil)
        // Manually trigger the donate menu item
        HelpMenubarItem.donate.triggerAction()
    }
}
