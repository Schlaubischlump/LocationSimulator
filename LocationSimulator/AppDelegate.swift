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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - MenuBar

    @IBAction func setLocation(_ sender: Any) {
        // Show the user an input textField to change the location.
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        // We can only request one location change at a time.
        if viewController.isShowingAlert {
            NSSound.beep()
        } else {
            viewController.requestTeleportOrNavigation()
        }
    }
}

