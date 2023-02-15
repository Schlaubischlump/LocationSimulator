//
//  AddDeveloperDiskImageAlert.swift
//  LocationSimulator
//
//  Created by David Klopp on 09.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

/// This is a panel subclass, that allows selecting a developer disk image, the corresponding signature file and the
/// iOS version. This class does not inherit from NSAlert, since we need more control over the button state.
class AddDeveloperDiskImageAlert: NSPanel {
    /// The os to download the files for e.g iPhone OS
    public private(set) var os: String

    public var version: String {
        return self.devDiskImageView.versionTextField.stringValue
    }

    public var developerDiskImageFile: URL {
        return URL(fileURLWithPath: self.devDiskImageView.imageFileTextField.stringValue)
    }

    public var developerDiskImageSignatureFile: URL {
        return URL(fileURLWithPath: self.devDiskImageView.signatureFileTextField.stringValue)
    }

    private var devDiskImageView: AddDeveloperDiskImageView {
        return (self.contentView as? AddDeveloperDiskImageView)!
    }

    override var canBecomeKey: Bool {
        return true
    }

    init(os: String) {
        self.os = os

        super.init(contentRect: NSRect(x: 0, y: 0, width: 500, height: 180),
                   styleMask: [.docModalWindow, .borderless],
                   backing: .buffered,
                   defer: false)

        self.contentView = AddDeveloperDiskImageView()
    }

}
