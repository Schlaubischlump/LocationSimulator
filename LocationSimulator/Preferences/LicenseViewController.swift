//
//  LicenseViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 16.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class LicenseViewController: NSViewController {

    @IBOutlet var licenseSelection: NSSegmentedControl!

    @IBOutlet var licenseTextView: NSTextView!

    /// Internal Reference to all licenses.
    private var licenses: [String: String] = [:]

    override func viewDidLoad() {
        // Get and store a reference to all licenses including their license text.
        self.licenses = FileManager.default.getLicenses()
        let licenseNames: [String] = licenses.keys.sorted()

        // Add a tab for each license.
        self.licenseSelection.segmentCount = licenseNames.count
        for (index, name) in licenseNames.enumerated() {
            self.licenseSelection.setLabel(name, forSegment: index)
            self.licenseSelection.setToolTip(name, forSegment: index)
        }
        self.licenseSelection.sizeToFit()

        // Select the first license.
        self.licenseSelection.selectedSegment = 0
        self.licenseSelectionChanged(self.licenseSelection)

        super.viewDidLoad()
    }

    @IBAction func licenseSelectionChanged(_ sender: NSSegmentedControl) {
        let selectedSegment = self.licenseSelection.selectedSegment
        // The license name is not localized. It is save to use it as dictionary key.
        if let title = self.licenseSelection.label(forSegment: selectedSegment),
           let licenseText = self.licenses[title] {
            // Show the license text inside the text view.
            self.licenseTextView.string = licenseText
            self.licenseTextView.alignment = .center

            // Scroll to the top of the license.
            let scrollView = self.licenseTextView.enclosingScrollView
            scrollView?.documentView?.scroll(.zero)
        }
    }
}
