//
//  AppDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /// The toolbar controller instance to handle the toolbar validation as well as the toolbar actions.
    @IBOutlet var menubarController: MenubarController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register the default setting values
        let defaults = UserDefaults.standard
        defaults.registerNetworkDefaultValues()
        defaults.registerRecentLocationDefaultValues()
        // Load the recent locations after the app finished launching.
        self.menubarController.loadRecentLocations()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
