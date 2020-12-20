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
        // load all recent locations menubaritems
        let items = RecentLocationMenubarItem.locations()
        items.reversed().forEach { item in
            RecentLocationMenubarItem.addLocationMenuItem(item)
        }
        // enable the clear menu item if required
        if items.count > 0 {
            // TODO: CRL
            RecentLocationMenubarItem.clearMenu.enable()
        }
    }

    //func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
