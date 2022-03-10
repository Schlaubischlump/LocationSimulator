//
//  DeveloperDiskImagesViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 07.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

enum Platform: String {
    case iPhoneOS = "iPhone OS"
    case watchOS = "Watch OS"

    // TV OS seems to report back as iPhone OS
    // case tvOS = "TV OS"

    // We use a variable and not a CaseIterable, to keep a user defined order
    static var values: [Platform] {
        return [.iPhoneOS, .watchOS]
    }
}

class DeveloperDiskImagesViewController: NSViewController {

    /// The main table view that lists all available os versions
    @IBOutlet var tableView: NSTableView!

    /// The segmented control to change the current platform
    @IBOutlet var platformSegment: NSSegmentedControl! {
        didSet {
            // Add a tab for each supported platform
            self.platformSegment.segmentCount = Platform.values.count
            for (i, platform) in Platform.values.enumerated() {
                self.platformSegment.setLabel(platform.rawValue, forSegment: i)
            }
            self.platformSegment.selectedSegment = 0
        }
    }

    /// The toolbar elements at the bottom of the table view
    @IBOutlet var toolbarSegment: NSSegmentedControl! {
        didSet {
            self.updateDesturctiveToolbarItems()
        }
    }

    /// All os versions available for the currently selected platform
    private var cachedOsVersions: [String] = []

    /// The currently selected platform
    private var selectedPlatform: String {
        return Platform.values[self.platformSegment.selectedSegment].rawValue
    }

    /// The currently selected os version
    private var selectedVersion: String? {
        let rowIndex = self.tableView.selectedRow
        if rowIndex >= 0 {
            return self.cachedOsVersions[rowIndex]
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the right click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "SHOW_IN_FINDER".localized,
                                action: #selector(openClikedInFinder(sender:)),
                                keyEquivalent: "")
        )
        self.tableView.menu = menu

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.reloadData()
    }

    /// Open the currently right clicked item in the Finder.
    @objc private func openClikedInFinder(sender: Any?) {
        let row = self.tableView.clickedRow
        guard row >= 0 else { return }

        let version = self.cachedOsVersions[row]
        if let path = FileManager.default.getDeveloperDiskImage(os: self.selectedPlatform, iOSVersion: version) {
            NSWorkspace.shared.open(path.deletingLastPathComponent())
        }
    }

    /// Add a new DeveleoperDiskImage.dmg + signature combination to the list by asking the user to download one or
    /// by selecting them from the file system.
    private func addNewDeveloperDiskImageFiles() {
        guard let window = self.view.window else { return }

        let alert = AddDeveloperDiskImageAlert(os: self.selectedPlatform)
        window.beginSheet(alert) { response in
            guard response == .OK else { return }

            let manager = FileManager.default
            if let devDiskPath = manager.getDeveloperDiskImage(os: alert.os, iOSVersion: alert.version),
                let devDiskSigPath = manager.getDeveloperDiskImageSignature(os: alert.os, iOSVersion: alert.version) {
                  try? manager.copyItem(at: alert.developerDiskImageFile, to: devDiskPath)
                  try? manager.copyItem(at: alert.developerDiskImageSignatureFile, to: devDiskSigPath)
                self.reloadData()
            }
        }
    }

    /// Delete the currently selected DeveleoperDiskImage.dmg + signature combination.
    private func deleteSelectedDeveloperDiskImageFiles() {
        guard let version = self.selectedVersion else { return }

        let fileManager = FileManager.default

        if fileManager.removeDownload(os: self.selectedPlatform, iOSVersion: version) {
            self.reloadData()
        } else {
            self.view.window?.showError("DEVDISK_DELETE_FAILED_ERROR", message: "DEVDISK_DELETE_FAILED_ERROR_MSG")
        }
    }

    /// Redownload the currently selected DeveleoperDiskImage.dmg + signature combination.
    private func refreshSelectedDeveloperDiskImageFiles() {
        guard let version = self.selectedVersion, let window = self.view.window else { return }

        let fileManager = FileManager.default

        // Backup the existing files
        let tmpDir = fileManager.temporaryDirectory
        let devDisk = fileManager.getDeveloperDiskImage(os: self.selectedPlatform, iOSVersion: version)!
        let devDiskSig = fileManager.getDeveloperDiskImageSignature(os: self.selectedPlatform, iOSVersion: version)!
        let devDiskTmp = tmpDir.appendingPathComponent(UUID().uuidString)
        let devDiskSigTmp = tmpDir.appendingPathComponent(UUID().uuidString)

        do {
            try fileManager.copyItem(at: devDisk, to: devDiskTmp)
            try fileManager.copyItem(at: devDiskSig, to: devDiskSigTmp)
        } catch {
            window.showError("DEVDISK_REFRESH_FAILED_ERROR", message: "DEVDISK_BACKUP_FAILED_ERROR_MSG")
        }

        // Download the new one
        let alert = ProgressAlert(os: self.selectedPlatform, version: version)
        let result = alert.runSheetModal(forWindow: window)
        if result == .failed {
            window.showError("DEVDISK_REFRESH_FAILED_ERROR", message: "DEVDISK_DOWNLOAD_FAILED_ERROR_MSG")
        }

        // The download failed or it was canceled => restore the original files
        if result != .OK {
            do {
                _ = try fileManager.replaceItemAt(devDisk, withItemAt: devDiskTmp)
                _ = try fileManager.replaceItemAt(devDiskSig, withItemAt: devDiskSigTmp)
            } catch {
                print("[ERROR]: \(self.selectedPlatform) \(version): Could not rollback DeveloperDiskImage files.")
            }
        }
    }

    /// Reload the data list with all currently downloaded os versions.
    private func reloadData() {
        let osVersions = FileManager.default.getAvailableVersions(os: self.selectedPlatform)
        self.cachedOsVersions = osVersions

        self.tableView.reloadData()
        self.updateDesturctiveToolbarItems()
    }

    @IBAction func platformSelectionDidChange(_ sender: NSSegmentedControl) {
        self.reloadData()
    }

    @IBAction func toolbarItemSelected(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: self.addNewDeveloperDiskImageFiles()          // Add
        case 1: self.deleteSelectedDeveloperDiskImageFiles()  // Remove
        case 2: self.refreshSelectedDeveloperDiskImageFiles() // Refresh
        default:
            break
        }
    }

    /// Disable the remove and refresh based on the current selection.
    private func updateDesturctiveToolbarItems() {
        let enabled = self.selectedVersion != nil
        self.toolbarSegment.setEnabled(enabled, forSegment: 1) // Remove item
        self.toolbarSegment.setEnabled(enabled, forSegment: 2) // Refresh item
    }
}

// MARK: - TableViewDataSource

extension DeveloperDiskImagesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.cachedOsVersions.count
    }
}

// MARK: - TableViewDelegate

extension DeveloperDiskImagesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView
        cell?.textField?.stringValue = self.cachedOsVersions[row]
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard notification.object as? NSTableView == self.tableView else { return }
        self.updateDesturctiveToolbarItems()
    }
}
