//
//  DeveloperDiskImagesViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 07.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit
import CLogger

let kDevDiskDefinitionUpdateKey: String = "com.schlaubischlump.locationsimulator.lastdeveloperdiskimagedefintionupdate"
let kCustomSupportDirectoryKey: String = "com.schlaubischlump.locationsimulator.customsupportdirectory"
let kCustomSupportDirectoryEnabledKey: String = "com.schlaubischlump.locationsimulator.customsupportdirectoryenabled"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var lastDeveloperDiskDefinitionUpdate: Date {
        get { Date(timeIntervalSince1970: self.double(forKey: kDevDiskDefinitionUpdateKey)) }
        set { self.setValue(newValue.timeIntervalSince1970, forKey: kDevDiskDefinitionUpdateKey) }
    }

    @objc dynamic var customSupportDirectoryEnabled: Bool {
        get { return self.bool(forKey: kCustomSupportDirectoryEnabledKey) }
        set { self.setValue(newValue, forKey: kCustomSupportDirectoryEnabledKey) }
    }

    @objc dynamic var customSupportDirectory: URL? {
        get {
            guard let data = self.data(forKey: kCustomSupportDirectoryKey) else { return nil }
            var isStale: Bool = false
            let url = try? URL(resolvingBookmarkData: data,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)

            // Try to renew our url if it is stale
            guard isStale else { return url }

            if let data = try? url?.bookmarkData(options: .withSecurityScope,
                                                 includingResourceValuesForKeys: nil,
                                                 relativeTo: nil) {
                self.setValue(data, forKey: kCustomSupportDirectoryKey)
                return try? URL(resolvingBookmarkData: data,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
            }
            return nil
        }
        set {
            if let data = try? newValue?.bookmarkData(options: .withSecurityScope,
                                                      includingResourceValuesForKeys: nil,
                                                      relativeTo: nil) {
                self.setValue(data, forKey: kCustomSupportDirectoryKey)
            }
        }
    }

    /// Register the default NSUserDefault values.
    func registerDeveloperDiskImagesDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kDevDiskDefinitionUpdateKey: 0.0,
            kCustomSupportDirectoryKey: URL(fileURLWithPath: ""),
            kCustomSupportDirectoryEnabledKey: false
        ])
    }
}

enum Platform: String {
    case iPhoneOS = "iPhone OS"
    case watchOS = "Watch OS"
    case tvOS = "Apple TVOS"

    // We use a variable and not a CaseIterable, to keep a user defined order
    static var values: [Platform] {
        return [.iPhoneOS, .watchOS, .tvOS]
    }
}

class DeveloperDiskImagesViewController: PreferenceViewControllerBase {

    /// The main table view that lists all available os versions
    @IBOutlet var tableView: NSTableView!

    @IBOutlet var customSupportPathCheckbox: NSButton!
    @IBOutlet var chooseCustomSupportPathButton: NSButton!
    @IBOutlet var customSupportPathTextField: NSTextField!
    @IBOutlet var customSupportPathFooter: NSTextField!

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
            self.updateToolbarItemsAvailibility()
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

        self.customSupportPathCheckbox.state = UserDefaults.standard.customSupportDirectoryEnabled ? .on : .off
        self.updateCustomSupportPathSelectionAvailibility()

        self.customSupportPathTextField.stringValue = UserDefaults.standard.customSupportDirectory?.path ?? ""

        // Setup the right click menu
        self.tableView.menu = self.createRightClickMenu()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.reloadData()
    }

    private func createRightClickMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "SHOW_IN_FINDER".localized,
                                action: #selector(openClikedInFinder(sender:)),
                                keyEquivalent: "")
        )
        return menu
    }

    /// Open the currently right clicked item in the Finder.
    @objc private func openClikedInFinder(sender: Any?) {
        let row = self.tableView.clickedRow
        guard row >= 0 else { return }

        let version = self.cachedOsVersions[row]
        FileManager.default.showDeveloperDiskImageInFinder(os: self.selectedPlatform, version: version)
    }

    /// Add a new DeveleoperDiskImage.dmg + signature combination to the list by asking the user to download one or
    /// by selecting them from the file system.
    private func addNewDeveloperDiskImageFiles() {
        guard let window = self.view.window else { return }

        let alert = AddDeveloperDiskImageAlert(os: self.selectedPlatform)
        window.beginSheet(alert) { response in
            guard response == .OK else { return }

            let manager = FileManager.default

            if let devDiskPath = manager.getDeveloperDiskImage(os: alert.os, version: alert.version),
                let devDiskSigPath = manager.getDeveloperDiskImageSignature(os: alert.os, version: alert.version) {

                try? manager.accessSupportDirectory {
                    try? manager.copyItem(at: alert.developerDiskImageFile, to: devDiskPath)
                    try? manager.copyItem(at: alert.developerDiskImageSignatureFile, to: devDiskSigPath)
                }

                self.reloadData()
            }
        }
    }

    /// Delete the currently selected DeveleoperDiskImage.dmg + signature combination.
    private func deleteSelectedDeveloperDiskImageFiles() {
        guard let version = self.selectedVersion else { return }

        let fileManager = FileManager.default

        if fileManager.removeDownload(os: self.selectedPlatform, version: version) {
            self.reloadData()
        } else {
            self.view.window?.showError("DEVDISK_DELETE_FAILED_ERROR", message: "DEVDISK_DELETE_FAILED_ERROR_MSG")
        }
    }

    /// Redownload the currently selected DeveleoperDiskImage.dmg + signature combination.
    private func refreshSelectedDeveloperDiskImageFiles() {
        guard let version = self.selectedVersion, let window = self.view.window else { return }

        let platform = self.selectedPlatform
        let fileManager = FileManager.default

        // Backup the existing files
        var token: BackupToken?
        do {
            token = try fileManager.backupSupportFiles(os: platform, version: version)
        } catch {
            window.showError("DEVDISK_REFRESH_FAILED_ERROR", message: "DEVDISK_BACKUP_FAILED_ERROR_MSG")
        }

        // Download the new files
        let alert = DownloadProgressAlert(os: platform, version: version)
        let result = alert.runSheetModal(forWindow: window)

        if result == .failed {
            window.showError("DEVDISK_REFRESH_FAILED_ERROR", message: "DEVDISK_DOWNLOAD_FAILED_ERROR_MSG")
        }

        // The download failed or it was canceled => restore the original files
        if result != .OK, let token = token {
            do {
                try fileManager.restoreSupportFiles(token: token)
            } catch {
                logError("\(platform) \(version): Could not rollback DeveloperDiskImage files.")
            }
        }
    }

    /// Reload the data list with all currently downloaded os versions.
    private func reloadData() {
        let osVersions = FileManager.default.getAvailableVersions(os: self.selectedPlatform)
        self.cachedOsVersions = osVersions

        self.tableView.reloadData()
        self.updateToolbarItemsAvailibility()
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

    /// Disable the toolbar items based on the current selection and the directory acccess rights.
    private func updateToolbarItemsAvailibility() {
        let enabled = self.selectedVersion != nil
        let isWriteable = FileManager.default.isSupportDirectoryWriteable

        self.toolbarSegment.setEnabled(isWriteable, forSegment: 0) // Add item
        self.toolbarSegment.setEnabled(enabled && isWriteable, forSegment: 1) // Remove item
        self.toolbarSegment.setEnabled(enabled && isWriteable, forSegment: 2) // Refresh item
    }

    /// Disable or enable the path selection button based on the checkbox.
    private func updateCustomSupportPathSelectionAvailibility() {
        let enabled = (self.customSupportPathCheckbox.state == .on)
        self.customSupportPathFooter.alphaValue = enabled ? 1.0 : 0.2
        // We can not allow the user to enter a path. The user must select the path, so that we can gain access to it.
        // Otherwise the sanbox blocks our attempt to access the file.
        self.customSupportPathTextField.isEnabled = false // enabled
        self.chooseCustomSupportPathButton.isEnabled = enabled
    }

    @IBAction func customPathCheckboxChanged(_ sender: NSButton) {
        if sender.state == .off {
            UserDefaults.standard.customSupportDirectoryEnabled = false
        } else {
            // If no path is currently selected show the path selection popup directly
            if  UserDefaults.standard.customSupportDirectory?.path.isEmpty ?? true {
                self.chooseCustomPath(sender)
            } else {
                UserDefaults.standard.customSupportDirectoryEnabled = true
            }
        }

        self.updateCustomSupportPathSelectionAvailibility()
        self.reloadData()
    }

    @IBAction func chooseCustomPath(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "CHOOSE_DEVELOPER_DISK_IMAGE_PATH_TITLE".localized
        if openPanel.runModal() == .OK {
            let url = openPanel.url
            self.customSupportPathTextField.stringValue = url?.path ?? ""

            UserDefaults.standard.customSupportDirectoryEnabled = true
            UserDefaults.standard.customSupportDirectory = url

            // Add a security bookmark to keep access to the file even after a restart of the application
            if UserDefaults.standard.customSupportDirectory == nil {
                self.view.window?.showError("CHANGING_SUPPORT_DIRECTORY_FAILED",
                                            message: "CHANGING_SUPPORT_DIRECTORY_FAILED_MSG")
            }

            self.reloadData()
        } else {
            // If the path is empty after the selection, disable the checkbox again
            if  UserDefaults.standard.customSupportDirectory?.path.isEmpty ?? true {
                self.customSupportPathCheckbox.state = .off
            }
        }
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
        self.updateToolbarItemsAvailibility()
    }
}
