//
//  Downloader.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation

class DownloadTask {
    /// ID to identify a task when the delegate methods are called
    public var dID: String!

    /// Source URL from where to download the data
    public var source: URL!

    /// Destination URL where to move the data after the download finished
    public var destination: URL!

    /// Optional description of the download process
    public var description: String!

    /// progress in percentage from 0.0 to 1.0
    public var progress: Double = 0.0

    /// Internal: download task object
    fileprivate var download: URLSessionDownloadTask?

    init(dID: String, source: URL, destination: URL, description: String = "") {
        self.dID = dID
        self.source = source
        self.destination = destination
        self.description = description
    }
}

class Downloader: NSObject, URLSessionDownloadDelegate {

    private var sessionConfig: URLSessionConfiguration!

    private var session: URLSession!

    /// list of all active tasks
    public var tasks: [Int: DownloadTask]!

    /// delegate to inform about download changes
    public weak var delegate: DownloaderDelegate?

    override init() {
        super.init()
        self.tasks = [:]
        self.sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue())
    }

    /*
     Start a new download process defined by a task instance.
     - Parameter task: download task instance
     */
    func start(_ task: DownloadTask) {
        task.download = self.session.downloadTask(with: task.source)
        self.tasks[task.download!.taskIdentifier] = task
        task.download?.resume()

        DispatchQueue.main.async {
            self.delegate?.downloadStarted(downloader: self, task: task)
        }
    }

    /*
     Cancel an active download process defined by a task instance.
     - Parameter task: download task instance
     */
    func cancel(_ task: DownloadTask) {
        if let taskID = task.download?.taskIdentifier {
            self.tasks.removeValue(forKey: taskID)
            task.download?.cancel()
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0, let task = self.tasks[downloadTask.taskIdentifier] else { return }

        task.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            self.delegate?.downloadProgressChanged(downloader: self, task: task)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = self.tasks[downloadTask.taskIdentifier] else { return }

        // check if the url response is valid
        if let response = downloadTask.response as? HTTPURLResponse, response.statusCode != 200 {
            self.urlSession(session, downloadTask: downloadTask,
                            didCompleteWithError: URLError(.init(rawValue: response.statusCode)))
        }

        // download seems to be okay => move the downloaded file to the destination
        self.tasks.removeValue(forKey: downloadTask.taskIdentifier)

        do {
            try? FileManager.default.removeItem(at: task.destination)
            try FileManager.default.moveItem(at: location, to: task.destination)

            DispatchQueue.main.async {
                self.delegate?.downloadFinished(downloader: self, task: task)
            }
        } catch let error {
            DispatchQueue.main.async {
                self.delegate?.downloadError(downloader: self, task: task, error: error)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = self.tasks[downloadTask.taskIdentifier], let error = error else { return }

        self.tasks.removeValue(forKey: downloadTask.taskIdentifier)

        DispatchQueue.main.async {
            self.delegate?.downloadError(downloader: self, task: task, error: error)
        }
    }
}
