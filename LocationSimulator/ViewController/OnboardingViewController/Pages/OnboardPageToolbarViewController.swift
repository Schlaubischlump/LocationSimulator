//
//  SidebarViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

class OnboardPageToolbarViewController: OnboardPageViewController {

    override func setup() {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "Toolbar")
        imageView.imageScaling = .scaleProportionallyDown
        let headerLabel = self.createHeaderLabel(text: "ONBOARD_TOOLBAR_HEADER".localized)
        let messageLabel = self.createMessageLabel(text: "ONBOARD_TOOLBAR_MESSAGE".localized)

        self.contentView.addArrangedSubview(imageView)
        self.contentView.addArrangedSubview(headerLabel)
        self.contentView.addArrangedSubview(messageLabel)
    }
}
