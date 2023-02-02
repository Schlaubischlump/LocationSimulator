//
//  SidebarViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

class OnboardPageFinishViewController: OnboardPageViewController {

    override func setup() {
        self.contentView.spacing = 15

        let headerLabel = self.createHeaderLabel(text: "ONBOARD_FINISH_HEADER".localized)
        let messageLabel = self.createMessageLabel(text: "ONBOARD_FINISH_MESSAGE".localized)
        let finishButton = NSButton(frame: .zero)
        finishButton.bezelStyle = .rounded
        finishButton.keyEquivalent = "\r"
        finishButton.title = "LETS_GO".localized
        finishButton.target = self
        finishButton.action = #selector(self.finishButtonClicked(_:))

        // Add a spacer
        let imageView = NSImageView()
        imageView.image = NSImage(named: "AppIcon")
        self.contentView.addArrangedSubview(imageView)
        self.contentView.addArrangedSubview(headerLabel)
        self.contentView.addArrangedSubview(messageLabel)
        self.contentView.addArrangedSubview(finishButton)
    }

    @objc func finishButtonClicked(_ sender: NSButton) {
        self.view.window?.close()
    }
}
