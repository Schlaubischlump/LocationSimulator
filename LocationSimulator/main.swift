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

// Init the logger before we start the application.
FileManager.default.initLogger()

// TODO: Check if we are running in commandline mode and if so, execute a command line tool instead of the UI

// Start the UI
let result = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
if result != 0 {
    logFatal("Unexpected Application exited with code \(result)")
}
