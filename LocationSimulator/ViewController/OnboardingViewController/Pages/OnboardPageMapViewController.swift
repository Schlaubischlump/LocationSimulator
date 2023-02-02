//
//  OnboardingPageMapViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

class OnboardPageMapViewController: OnboardPageViewController {

    private lazy var userLocationView: UserLocationView = {
        return UserLocationView(frame: CGRect(origin: .zero, size: UserLocationView.defaultSize))
    }()

    private lazy var imageView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "Map")
        imageView.imageScaling = .scaleProportionallyDown
        imageView.addSubview(self.userLocationView)
        return imageView
    }()

    override func setup() {
        let headerLabel = self.createHeaderLabel(text: "ONBOARD_MAP_HEADER".localized)
        let messageLabel = self.createMessageLabel(text: "ONBOARD_MAP_MESSAGE".localized)

        self.contentView.addArrangedSubview(self.imageView)
        self.contentView.addArrangedSubview(headerLabel)
        self.contentView.addArrangedSubview(messageLabel)
    }

    override func doLayout() {
        super.doLayout()
        let locationViewFrame = self.userLocationView.frame
        var pos = CGPoint(x: self.imageView.bounds.midX, y: self.imageView.bounds.midY)
        pos.x -= locationViewFrame.width/2
        pos.y -= locationViewFrame.height/2
        self.userLocationView.frame.origin = pos
    }
}
