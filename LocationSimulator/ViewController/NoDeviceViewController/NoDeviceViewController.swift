//
//  NoDeviceViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

// The detailed view controller displayed when no device is connectd.
import AppKit

class NoDeviceViewController: NSViewController {

    @IBOutlet weak var noDeviceView: NoDeviceView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the `no device` text when the view finished loading.
        self.noDeviceView.set(title: "NO_DEVICE".localized, message: "NO_DEVICE_MSG".localized)
    }
}
