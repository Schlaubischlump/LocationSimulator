//
//  AddDeveloperDiskImageView.swift
//  LocationSimulator
//
//  Created by David Klopp on 09.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class AddDeveloperDiskImageView: NSView {
    @IBOutlet var contentView: NSView!

    @IBOutlet var imageFileTextField: NSTextField!
    @IBOutlet var signatureFileTextField: NSTextField!
    @IBOutlet var versionTextField: NSTextField!

    @IBOutlet var devImageDropBox: DragAndDropBox!
    @IBOutlet var devSignatureDropBox: DragAndDropBox!

    @IBOutlet var addButton: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        // Load the contentView and set its size to update automatically.
        Bundle.main.loadNibNamed("AddDeveloperDiskImageView", owner: self, topLevelObjects: nil)
        self.contentView.autoresizingMask = [.width, .height]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.contentView.frame = self.bounds
        self.addSubview(self.contentView)

        // Only enable the addButton if the user filled out the form correctly
        self.addButton.isEnabled = false
        self.versionTextField.delegate = self
        self.imageFileTextField.delegate = self
        self.signatureFileTextField.delegate = self

        // Setup drag and drop
        self.devImageDropBox.allowedTypes = ["dmg"]
        self.devImageDropBox.dropHandler = { filePath in
            self.imageFileTextField.stringValue = filePath
            self.updateAddButtonAvailability()
        }

        self.devSignatureDropBox.allowedTypes = ["signature"]
        self.devSignatureDropBox.dropHandler = { filePath in
            self.signatureFileTextField.stringValue = filePath
            self.updateAddButtonAvailability()
        }
    }

    @IBAction func add(_ sender: NSButton) {
        guard let window = self.window else { return }

        // Make sure we have a valid version number before we exit
        var version = self.versionTextField.stringValue
        if version.last == "." {
            version += "0"
        }
        if !version.contains(where: { $0 == "." }) {
            version += ".0"
        }
        self.versionTextField.stringValue = version
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }

    @IBAction func cancel(_ sender: NSButton) {
        guard let window = self.window else { return }
        window.sheetParent?.endSheet(window, returnCode: .cancel)
    }

    @IBAction func selectDeveloperDiskImage(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["dmg"]
        openPanel.title = "SELECT_DEVELOPER_DISK_IMAGE_TITLE".localized
        if openPanel.runModal() == .OK {
            self.imageFileTextField.stringValue = openPanel.url?.path ?? ""
        }
        self.updateAddButtonAvailability()
    }

    @IBAction func selectDeveloperDiskImageSignature(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["signature"]
        openPanel.title = "SELECT_DEVELOPER_DISK_IMAGE_SIGNATURE_TITLE".localized
        if openPanel.runModal() == .OK {
            self.signatureFileTextField.stringValue = openPanel.url?.path ?? ""
        }
        self.updateAddButtonAvailability()
    }

    private func updateAddButtonAvailability() {
        let imageFile = self.imageFileTextField.stringValue
        let signatureFile = self.signatureFileTextField.stringValue

        // Check if the files are valid
        var isDir: ObjCBool = false
        let fileManager = FileManager.default
        let imageExists = fileManager.fileExists(atPath: imageFile, isDirectory: &isDir) && !isDir.boolValue
        let signatureExists = fileManager.fileExists(atPath: signatureFile, isDirectory: &isDir) && !isDir.boolValue

        // Update the preview on the right side
        if imageExists && imageFile.split(separator: ".").last == "dmg" {
            self.devImageDropBox.filePath = imageFile
        }
        if signatureExists && signatureFile.split(separator: ".").last == "signature"{
            self.devSignatureDropBox.filePath = signatureFile
        }

        let hasVersionNumber = !self.versionTextField.stringValue.isEmpty

        self.addButton.isEnabled = imageExists && signatureExists && hasVersionNumber
    }
}

extension AddDeveloperDiskImageView: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        self.updateAddButtonAvailability()
    }
}
