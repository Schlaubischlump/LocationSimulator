//
//  AppDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var menubarController: MenubarController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register all the default setting values for this application.
        let defaults = UserDefaults.standard
        defaults.registerInfoDefaultValues()
        defaults.registerGeneralDefaultValues()
        defaults.registerNetworkDefaultValues()
        defaults.registerMapTypeDefaultValue()
        defaults.registerRecentLocationDefaultValues()
        defaults.registerDeveloperDiskImagesDefaultValues()

        self.menubarController.loadDefaults()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        self.openInfoViewOnVersionUpdate()
    }

    /// Open the InfoViewController when the version number changed. This way we can inform the user about critical
    /// changes and remind him/her to donate ;)
    private func openInfoViewOnVersionUpdate() {
        let defaults = UserDefaults.standard
        if defaults.lastAppVersion != kAppVersion {
            // Segue would be nicer, but does not work
            AppMenubarItem.preferences.triggerAction()
            // Update the last app version
            defaults.lastAppVersion = kAppVersion
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Reset the location for every device that currently has a spoofed location. We are not interested in updating
        // any window UI, since we are closing the app. We therefore directly access the device and make a synchronous
        // call to reset the location.
        NSApplication.shared.windows.forEach { window in
            let windowController = window.windowController as? WindowController
            let device = windowController?.mapViewController?.device
            device?.disableSimulation()
        }
    }
}
