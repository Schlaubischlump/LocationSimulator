//
//  ProgressViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class ProgressViewController: NSViewController {
    /// Label above the download bar at the top.
    @IBOutlet weak var statusLabelTop: NSTextField!
    /// Label above the download bar at the bottom.
    @IBOutlet weak var statusLabelBottom: NSTextField!
    /// Download bar at the top of the window.
    @IBOutlet weak var progressIndicatorTop: NSProgressIndicator!
    /// Download bar at the bottom of the window.
    @IBOutlet weak var progressIndicatorBottom: NSProgressIndicator!

    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard let win = self.view.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
