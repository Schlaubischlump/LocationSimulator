//
//  LoggerWindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 12.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class LogWindowController: NSWindowController {
    @IBOutlet var toolbarController: LogToolbarController!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = self.contentViewController?.title ?? ""
    }
}
