//
//  ProgressView+DownloadDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import Downloader

let kDevDiskTaskID = "DevDisk"
let kDevSignTaskID = "DevSign"

/// Extension which takes care of the `DeveloperDiskImage` and `DeveloperDiskImage.sign` download progress and updates
/// the UI accordingly.
extension ProgressView: DownloaderDelegate {
    func downloadStarted(downloader: Downloader, task: DownloadTask) {
        let progressBar = (task.dID == kDevDiskTaskID) ? self.progressBarTop : self.progressBarBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom

        progressBar!.doubleValue = 0.0
        statusLabel!.stringValue = task.description
    }

    func downloadCanceled(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count != 0, let win = self.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count == 0, let win = self.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .OK)
    }

    func downloadProgressChanged(downloader: Downloader, task: DownloadTask) {
        let progressBar = (task.dID == kDevDiskTaskID) ? self.progressBarTop : self.progressBarBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom

        progressBar!.doubleValue = task.progress
        statusLabel!.stringValue = task.description + ": " + String(format: "%.2f", task.progress*100) + "%"
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        guard let win = self.window else { return }
        // show the error to the user
        win.sheetParent?.showError(NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR", comment: ""),
                                   message: NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR_MSG", comment: ""))
        // dismiss the download window
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }
}
