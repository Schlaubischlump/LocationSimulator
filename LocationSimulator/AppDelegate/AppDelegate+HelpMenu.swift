//
//  AppDelegate+HelpMenu.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kProjectWebsite = "https://github.com/Schlaubischlump/LocationSimulator"

extension AppDelegate {
    /// Open the main project website in a browser.
    @IBAction func openProjectPage(_ sender: Any) {
        if let url = URL(string: kProjectWebsite) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open the report an issue website in a browser.
    @IBAction func reportBugPage(_ sender: Any) {
        if let url = URL(string: kProjectWebsite + "/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}
