//
//  DonateDetailViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class DonateDetailViewController: NSViewController {

    @IBOutlet var qrCodeImageView: NSImageView!

    @IBOutlet var linkLabel: NSTextField!

    @IBOutlet var donateButton: NSButton!

    @IBOutlet var qrCodeImageViewTopConstraint: NSLayoutConstraint!


    public var donateMethod: DonateMethod? {
        didSet {
            if self.isViewLoaded {
                self.reloadDetails()
            }
        }
    }

    private func reloadDetails() {
        guard let donateMethod = self.donateMethod else { return }

        self.qrCodeImageView.image = .generateQrCode(donateMethod.value, size: CGSize(width: 1024, height: 1024))

        var attributes: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 13.0)]
        if let linkURL = donateMethod.linkURL {
            attributes[.link] = linkURL
        }
        self.linkLabel.attributedStringValue = NSAttributedString(string: donateMethod.value, attributes: attributes)
        self.donateButton.title = donateMethod.actionTitle
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(macOS 11.0, *) {
            // Nothing to do here, since the safeAreaInset is respected
        } else {
            // Fix the layout for older macOS versions
            self.qrCodeImageViewTopConstraint.constant = -25
        }
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        self.reloadDetails()
    }

    @IBAction func donateButtonClicked(_ sender: NSButton) {
        self.donateMethod?.performAction()
    }
}
