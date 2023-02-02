//
//  SidebarViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

class OnboardPageSidebarViewController: OnboardPageViewController {

    override func setup() {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "Sidebar")
        imageView.wantsLayer = true
        imageView.imageScaling = .scaleProportionallyDown
        let headerLabel = self.createHeaderLabel(text: "ONBOARD_SIDEBAR_HEADER".localized)
        let messageLabel = self.createMessageLabel(text: "ONBOARD_SIDEBAR_MESSAGE".localized)

        self.contentView.addArrangedSubview(imageView)
        self.contentView.addArrangedSubview(headerLabel)
        self.contentView.addArrangedSubview(messageLabel)
    }
}
