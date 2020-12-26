//
//  ProgressView+DownloadDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import Downloader

let kDevDiskTaskID = "DevDisk"
let kDevSignTaskID = "DevSign"

/// Extension which takes care of the `DeveloperDiskImage` and `DeveloperDiskImage.sign` download progress and updates
/// the UI accordingly.
extension ProgressView: DownloaderDelegate {

    // MARK: - Helper that should run on main thread

    @objc private func updateUIForStart(task: DownloadTask) {
        let progressBar = (task.dID == kDevDiskTaskID) ? self.progressBarTop : self.progressBarBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom

        progressBar!.doubleValue = 0.0
        statusLabel!.stringValue = task.desc
    }

    @objc private func updateUIForProgress(task: DownloadTask) {
        let progressBar = (task.dID == kDevDiskTaskID) ? self.progressBarTop : self.progressBarBottom
        let statusLabel = (task.dID == kDevDiskTaskID) ? self.statusLabelTop : self.statusLabelBottom
        let progress = task.progress*100
        //if (progress - progressBar!.doubleValue) > 5 {
            progressBar!.doubleValue = progress
        //}
        statusLabel!.stringValue = task.desc + ": " + String(format: "%.2f", progress) + "%"
    }

    // MARK: - Delegate

    func downloadStarted(downloader: Downloader, task: DownloadTask) {
        // We can not use `DispatchQueue` here, because `DispatchQueue` runs on the .common RunLoop.
        // This is the same runloop that modal dialogs use. Therefore use `performSelector` which runs on the default
        // loop.
        self.performSelector(onMainThread: #selector(updateUIForStart(task:)), with: task, waitUntilDone: true)
    }

    func downloadProgressChanged(downloader: Downloader, task: DownloadTask) {
        self.performSelector(onMainThread: #selector(updateUIForProgress(task:)), with: task, waitUntilDone: true)
    }

    func downloadCanceled(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count == 0 else { return }
        self.downloadFinishedAction?(.cancel)
    }

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count == 0 else { return }
        self.downloadFinishedAction?(.success)
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        self.downloadFinishedAction?(.failure)
    }
}
