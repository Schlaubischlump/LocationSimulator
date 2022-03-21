//
//  LogToolbarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 12.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class LogToolbarController: NSResponder {
    /// The corresponding windowController for this toolbar controller.
    @IBOutlet weak var windowController: LogWindowController?

    private var viewController: LogViewController? {
        return self.windowController?.window?.contentViewController as? LogViewController
    }

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @IBAction func refreshClicked(_ sender: NSButton) {
        logger_flush()
        self.viewController?.reloadData()
    }

    @IBAction func exportClicked(_ sender: NSButton) {
        guard let window = self.windowController?.window else { return }

        guard let logData = self.viewController?.logData else {
            window.showError("CREATE_LOG_FAILED", message: "CREATE_LOG_FAILED_MSG")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.title = "EXPORT_LOG_TITLE".localized
        savePanel.nameFieldStringValue = "locationsimulator.log"
        savePanel.showsHiddenFiles = false
        savePanel.allowedFileTypes = ["log"]
        savePanel.allowsOtherFileTypes = false
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK else { return }

            do {
                try logData.write(to: savePanel.url!)
            } catch {
                window.showError("SAVE_LOG_FAILED", message: "SAVE_LOG_FAILED_MSG")
            }
        }
    }

    @IBAction func clearLogClicked(_ sender: NSButton) {
        let fileManager = FileManager.default
        if !fileManager.deleteActiveLog() || !fileManager.deleteBackupLogs() {
            self.windowController?.window?.showError("DELETE_LOG_FAILED", message: "DELETE_LOG_FAILED_MSG")
        } else {
            self.viewController?.reloadData()
        }
    }
}
