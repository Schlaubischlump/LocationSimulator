//
//  DownloadProgressTask.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import Downloader

extension DownloadTask: ProgressTask {
    // Configuration
    var showSpinner: Bool { return true }
    var showProgress: Bool { return true }

    func description(forProgress progress: Double) -> String {
        return "\(self.desc!): \(Int(progress*100))%"
    }
}
