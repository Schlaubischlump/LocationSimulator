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
        // Init the logger
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFile = documentDir.appendingPathComponent("log.txt")

        logger_initConsoleLogger(nil)
        logger_initFileLogger(logFile.path, 1024*1024*5, 5) // 5MB limit per file

        // Register all the default setting values for this application.
        let defaults = UserDefaults.standard
        defaults.registerGeneralDefaultValues()
        defaults.registerNetworkDefaultValues()
        defaults.registerRecentLocationDefaultValues()
        // Load the recent locations after the app finished launching.
        self.menubarController.loadRecentLocations()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
