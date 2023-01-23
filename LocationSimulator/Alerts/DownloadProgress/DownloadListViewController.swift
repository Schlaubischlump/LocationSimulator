//
//  DownloadListViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import Downloader
import AppKit

let kDevDiskTaskID = "DevDisk"
let kDevSignTaskID = "DevSign"

public enum DownloadStatus: Int {
    case failure
    case success
    case cancel
}

typealias DownloadCompletionHandler = (DownloadStatus) -> Void

class DownloadListViewController: NSViewController {
    /// The downloader instance to manage.
    public let downloader: Downloader = Downloader()

    /// The action to perform when the download is finished.
    public var downloadFinishedAction: DownloadCompletionHandler?

    /// True if the download progress is active.
    private var isDownloading = false

    /// True if the support directory is currently accessed, False otherwise
    public private(set) var isAccessingSupportDir: Bool = false

    private var progressListView: ProgressListView? {
        self.view as? ProgressListView
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.downloader.delegate = self
    }

    override func loadView() {
        self.view = ProgressListView(frame: CGRect(x: 0, y: 0, width: 400, height: 140))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func prepareDownload(os: String, iOSVersion: String) -> Bool {
        // Check if the path for the image and signature file can be created.
        let manager = FileManager.default
        guard let devDMG = manager.getDeveloperDiskImage(os: os, version: iOSVersion),
              let devSign = manager.getDeveloperDiskImageSignature(os: os, version: iOSVersion) else {
            return false
        }

        // Get the download links from the internal plist file.
        let (diskLinks, signLinks) = manager.getDeveloperDiskImageDownloadLinks(os: os, version: iOSVersion)
        if diskLinks.isEmpty || signLinks.isEmpty {
            return false
        }

        // We use the first download link. In theory we could add multiple links for the same image.
        let devDiskTask = DownloadTask(dID: kDevDiskTaskID, source: diskLinks[0], destination: devDMG,
                                       description: "DEVDISK_DOWNLOAD_DESC".localized)
        let devSignTask = DownloadTask(dID: kDevSignTaskID, source: signLinks[0], destination: devSign,
                                       description: "DEVSIGN_DOWNLOAD_DESC".localized)

        self.progressListView?.add(task: devDiskTask)
        self.progressListView?.add(task: devSignTask)

        return true
    }

    /// Start the download of the DeveloperDiskImages.
    /// - Return: true on success, false otherwise.
    @discardableResult
    @objc func startDownload() -> Bool {
        guard !self.isDownloading else { return false }

        self.isDownloading = true
        // Start the downlaod process.
        self.isAccessingSupportDir = FileManager.default.startAccessingSupportDirectory()
        self.progressListView?.tasks.forEach {
            guard let task = ($0 as? DownloadTask) else { return }
            self.downloader.start(task)
        }
        return true
    }

    /// Cancel the current download.
    /// - Return: true on success, false otherwise.
    @discardableResult
    @objc func cancelDownload() -> Bool {
        guard self.isDownloading else { return false }

        self.progressListView?.tasks.forEach {
            guard let task = ($0 as? DownloadTask) else { return }
            self.downloader.cancel(task)
        }

        // Cleanup
        self.isDownloading = false
        return true
    }
}

extension DownloadListViewController: DownloaderDelegate {
    /*func downloadStarted(downloader: Downloader, task: DownloadTask) {
        // nothing to do here
    }

    func downloadProgressChanged(downloader: Downloader, task: DownloadTask) {
        // nothing to do here
    }*/

    func downloadCanceled(downloader: Downloader, task: DownloadTask) {
        guard downloader.tasks.count == 0 else { return }

        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }
        self.downloadFinishedAction?(.cancel)
    }

    @objc private func removeTask(task: DownloadTask) {
        self.progressListView?.remove(task: task)
    }

    @objc private func finishDownload() {
        self.downloadFinishedAction?(.success)
    }

    // This is hacky as fuck... Why is this necessary you may ask ?
    // Well we will add this viewcontroller's view to the content of an NSAlert. The NSAlert will run as a sheet modal.
    // That means, the modalPanel runloop will be used. DispatchQueue.main will not run while the Runloop is executing
    // in modalPanel mode. Timer and all those other fancy APIs will not work as well. So the only working solution
    // I came up with, was to spawn a thread and just wait till we are ready to perform the dismiss task on the main
    // thread. Note that performSelectorOnMainThread is indeed executed even in modalPanel mode, unlike the
    // DispatchQueue.
    @objc private func performSelector(onMainThread selector: Selector,
                                       with object: Any?,
                                       waitUntilDone: Bool,
                                       afterDelay delay: Double) {
        let thread = Thread {
            let refDate = Date()
            while abs(refDate.timeIntervalSinceNow) < delay {
                // just wait
            }
            self.performSelector(onMainThread: selector, with: object, waitUntilDone: waitUntilDone)
        }
        thread.start()
    }

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        // Give the animations some time to finish
        self.performSelector(onMainThread: #selector(self.removeTask(task:)),
                             with: task,
                             waitUntilDone: false,
                             afterDelay: 1.0
        )

        guard downloader.tasks.count == 0 else { return }
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }

        // Give the animations some time to finish
        self.performSelector(onMainThread: #selector(self.finishDownload),
                             with: nil,
                             waitUntilDone: false,
                             afterDelay: 1.0
        )
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }
        self.downloadFinishedAction?(.failure)
    }
}
