//
//  DownloadProgressTask.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import Downloader

class DownloadTaskWrapper: ProgressTask {
    // State
    let task: DownloadTask
    var progress: Float {
        return Float(self.task.progress)
    }

    internal init(downloadTask: DownloadTask) {
        self.task = downloadTask
    }

    // Configuration
    var showSpinner: Bool = true
    var showProgress: Bool = true

    func description(forProgress progress: Float) -> String {
        return "\(self.task.desc!): \(Int(progress*100))%"
    }

    // Control download progress by calling these
    var onProgress: ((Float) -> Void)?
    var onCompletion: ((Float) -> Void)?
    var onError: ((Error) -> Void)?
}
