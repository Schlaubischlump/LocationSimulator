//
//  DownloadListViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit
import Downloader
import CLogger

let kUpdateDevTaskID = "UpdateDev"

public enum DownloadStatus: Int {
    case failure
    case success
    case cancel
}

typealias DownloadCompletionHandler = (DownloadStatus) -> Void

class DownloadListViewController: NSViewController {
    /// The downloader instance to manage.
    public let downloader: Downloader = Downloader()

    /// The action to perform when the update of the developer disk image links is finished.
    public var updateFinishedAction: DownloadCompletionHandler?

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

    /// Update the DeveloperDiskImage download links if required.
    /// - Return: true on success, false otherwise
    @discardableResult
    @objc func updateDeveloperDiskImageDownloadLinks() -> Bool {
        // Only update once every 5 minutes
        let lastUpdateDate = UserDefaults.standard.lastDeveloperDiskDefinitionUpdate
        guard abs(lastUpdateDate.timeIntervalSinceNow) >= 300 else {
            DispatchQueue.main.async {
                self.updateFinishedAction?(.success)
            }
            return true
        }

        // If we can not get the path to store the definition file we just fail right here
        guard let src = URL(string: kDeveloperDiskImagesInfo),
              let dest = DeveloperDiskImage.downloadDefinitionsFile else {
            DispatchQueue.main.async {
                self.updateFinishedAction?(.failure)
            }
            return false
        }

        // Start the update process
        let descr = "DEVDISK_UPDATE_DESC".localized
        let updateTask = DownloadTask(dID: kUpdateDevTaskID, source: src, destination: dest, description: descr)
        self.progressListView?.add(task: updateTask)

        self.isAccessingSupportDir = FileManager.default.startAccessingSupportDirectory()
        self.isDownloading = true
        self.downloader.start(updateTask)

        return true
    }

    private func downloadDescription(file: DeveloperDiskImage.SupportFile) -> String {
        switch file {
        case .image: return "DEVDISK_DOWNLOAD_DESC".localized
        case .signature: return "DEVSIGN_DOWNLOAD_DESC".localized
        case .trustcache: return "DEVTRUST_DOWNLOAD_DESC".localized
        case .buildManifest: return "DEVMANIFEST_DOWNLOAD_DESC".localized
        }
    }

    /// Prepare the download of a DeveloperDiskImage and all corresponding files.
    /// - Parameter developerDiskImage: the DeveloperDiskImage to download
    /// - Return: true on success, false otherwise
    @discardableResult
    @objc func prepareDownload(_ developerDiskImage: DeveloperDiskImage) -> Bool {
        // Get the download links from the internal plist file.
        var res: Bool = true

        var downloadTasks = developerDiskImage.downloadLinks.compactMap { (file, link) in
            if let destFile = file.url {
                let desc = downloadDescription(file: file)
                return DownloadTask(dID: file.description, source: link, destination: destFile, description: desc)
            } else {
                return nil
            }
        }

        if downloadTasks.isEmpty {
            res = false

            // Add dummy tasks to make the UI nicer
            let dummyURL = URL(string: kProjectWebsite)!
            let tmpDir = FileManager.default.temporaryDirectory
            let dummyFile = tmpDir.appendingPathComponent(UUID().uuidString, isDirectory: false)
            downloadTasks = [
                DownloadTask(dID: "dummy1", source: dummyURL, destination: dummyFile),
                DownloadTask(dID: "dummy2", source: dummyURL, destination: dummyFile)
            ]
        }

        downloadTasks.forEach {
            self.progressListView?.add(task: $0)
        }

        return res
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
        self.isDownloading = false

        if task.dID == kUpdateDevTaskID {
            self.updateFinishedAction?(.cancel)
        } else {
            self.downloadFinishedAction?(.cancel)
        }
    }

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        // Give the progress fill animation some time to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.progressListView?.remove(task: task)
        }

        guard downloader.tasks.count == 0 else { return }
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }

        // Give the remove animation some time to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isDownloading = false

            if task.dID == kUpdateDevTaskID {
                UserDefaults.standard.lastDeveloperDiskDefinitionUpdate = Date()
                UserDefaults.standard.synchronize()
                self.updateFinishedAction?(.success)
            } else {
                self.downloadFinishedAction?(.success)
            }
        }
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }
        self.isDownloading = false

        if task.dID == kUpdateDevTaskID {
            self.updateFinishedAction?(.failure)
        } else {
            self.downloadFinishedAction?(.failure)
        }
    }
}
