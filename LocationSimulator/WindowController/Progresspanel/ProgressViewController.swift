//
//  ProgressViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

/// A simple view which displays two progress bars with a corresponding status label for each bar.
class ProgressViewController: NSViewController {
    /// Label above the download bar at the top.
    @IBOutlet weak var statusLabelTop: NSTextField!
    /// Label above the download bar at the bottom.
    @IBOutlet weak var statusLabelBottom: NSTextField!
    /// Download bar at the top of the window.
    @IBOutlet weak var progressIndicatorTop: NSProgressIndicator!
    /// Download bar at the bottom of the window.
    @IBOutlet weak var progressIndicatorBottom: NSProgressIndicator!

    /// The user canceled the progress view.
    /// - Parameter sender: the button clicked to cancel the view.
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard let win = self.view.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
