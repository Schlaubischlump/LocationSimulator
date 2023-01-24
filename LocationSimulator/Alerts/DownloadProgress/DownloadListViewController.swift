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

let kDevDiskTaskID = "DevDisk"
let kDevSignTaskID = "DevSign"

public enum DownloadStatus: Int {
    case failure
    case success
    case cancel
}

typealias DownloadCompletionHandler = (DownloadStatus) -> Void

class DownloadListViewController: NSViewController {
    typealias Platform = String
    typealias Version = String
    typealias FileType = String
    typealias JSonType = [Platform: [Version: [FileType: [String]]]]

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

    /// Parse the DeveloperDiskImages.json and return the download links for all DeveloperDiskImages files for every
    /// iOS version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
    private func getDeveloperDiskImageDownloadLinks(os: String, version: String) -> [String: [URL]] {
        // TODO: This should just access the file from the disk
        // TODO: We should first start a task to download the file
        // Check if the plist file and the platform inside the file can be found.
        guard let jsonPath = URL(string: kDeveloperDiskImagesInfo),
              let jsonData = try? Data(contentsOf: jsonPath, options: .mappedIfSafe),
              let jsonResult = try? JSONSerialization.jsonObject(with: jsonData) as? JSonType else {
            logError("DeveloperDiskImages.json not found!")
            return [:]
        }

        let osLinks = jsonResult[os] ?? [:]
        let versionLinks = osLinks[version] ?? [:]
        let fallbackLinks = osLinks["Fallback"] ?? [:]
        let resolvedFallbackLinks = fallbackLinks.mapValues { $0.map { String(format: $0, version) } }

        let downloadLinks = versionLinks.merging(resolvedFallbackLinks) { $0 + $1 }
        if downloadLinks.isEmpty {
            logError("DeveloperDiskImages.json does not contain any download links!")
        }

        return downloadLinks.mapValues { links in
            links.compactMap {
                URL(string: $0)
            }
        }
    }

    @objc func prepareDownload(os: String, iOSVersion: String) -> Bool {
        // Check if the path for the image and signature file can be created.
        let manager = FileManager.default
        guard let devDmgPath = manager.getDeveloperDiskImage(os: os, version: iOSVersion),
              let devSignPath = manager.getDeveloperDiskImageSignature(os: os, version: iOSVersion) else {
            return false
        }

        // Get the download links from the internal plist file.
        let links = self.getDeveloperDiskImageDownloadLinks(os: os, version: iOSVersion)

        let diskLinks = links["Image"] ?? []
        let signLinks = links["Signature"] ?? []

        // We use the first download link. In theory we could add multiple links for the same image.
        guard !diskLinks.isEmpty && !signLinks.isEmpty else {
            return false
        }

        let dmgTask = DownloadTask(dID: kDevDiskTaskID, source: diskLinks[0], destination: devDmgPath,
                                   description: "DEVDISK_DOWNLOAD_DESC".localized)
        let sigTask = DownloadTask(dID: kDevSignTaskID, source: signLinks[0], destination: devSignPath,
                                   description: "DEVSIGN_DOWNLOAD_DESC".localized)

        self.progressListView?.add(task: dmgTask)
        self.progressListView?.add(task: sigTask)

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

    func downloadFinished(downloader: Downloader, task: DownloadTask) {
        // Give the progress fill animation some time to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.progressListView?.remove(task: task)
        }

        guard downloader.tasks.count == 0 else { return }
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }

        // Give the remove animation some time to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.downloadFinishedAction?(.success)
        }
    }

    func downloadError(downloader: Downloader, task: DownloadTask, error: Error) {
        if self.isAccessingSupportDir { FileManager.default.stopAccessingSupportDirectory() }
        self.downloadFinishedAction?(.failure)
    }
}
