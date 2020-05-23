//
//  PogressWindowController+DownloaderDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation

let kDevDiskTaskID = "DevDisk"
let kDevSignTaskID = "DevSign"

extension ProgressViewController: DownloaderDelegate {
    func downloadStarted(downloader: Downloader, task: DownloadTask) {
        let progressIndicator = (task.dID == kDevDiskTaskID) ? self.progressIndicatorTop : self.progressIndicatorBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom

        progressIndicator!.doubleValue = 0.0
        statusLabel!.stringValue = task.description
    }

    func downloadCanceled(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count != 0, let win = self.view.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count == 0, let win = self.view.window else { return }
        win.sheetParent?.endSheet(win, returnCode: .OK)
    }

    func downloadProgressChanged(downloader: Downloader, task: DownloadTask) {
        let progressIndicator = (task.dID == kDevDiskTaskID) ? self.progressIndicatorTop : self.progressIndicatorBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom

        progressIndicator!.doubleValue = task.progress
        statusLabel!.stringValue = task.description + ": " + String(format: "%.2f", task.progress*100) + "%"
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        guard let win = self.view.window else { return }
        // show the error to the user
        win.sheetParent?.showError(NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR", comment: ""),
                                   message: NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR_MSG", comment: ""))
        // dismiss the download window
        win.sheetParent?.endSheet(win, returnCode: .cancel)
    }
}
