//
//  main.swift
//  LocationSimulator
//
//  Created by David Klopp on 07.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import CLogger
import LocationSpoofer

// Init the logger before we start the application.
FileManager.default.initLogger()

// Register all the default setting values for this application.
let defaults = UserDefaults.standard
defaults.registerInfoDefaultValues()
defaults.registerGeneralDefaultValues()
defaults.registerNetworkDefaultValues()
defaults.registerMapTypeDefaultValue()
defaults.registerRecentLocationDefaultValues()
defaults.registerDeveloperDiskImagesDefaultValues()

/// Start the application without any UI and without any dock or menubar entry. This is useful if you want to use the
/// application as an AppleScript service.
func launchWithoutUI() {
    IOSDevice.startGeneratingDeviceNotifications()
    SimulatorDevice.startGeneratingDeviceNotifications()

    let app = Application.shared
    // We do not want to create a dock or a menubar entry
    app.setActivationPolicy(.prohibited)
    app.run()

    IOSDevice.stopGeneratingDeviceNotifications()
    SimulatorDevice.stopGeneratingDeviceNotifications()
}

/// Start the application normally with a UI.
func launchWithUI() {
    let result = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    if result != 0 {
        logFatal("Unexpected application exit with code \(result)")
    }
}

// Launch the application.
let args = CommandLine.arguments
if args.contains("--no-ui") {
    launchWithoutUI()
} else {
    launchWithUI()
}
