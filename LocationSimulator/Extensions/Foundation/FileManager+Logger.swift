//
//  FileManager+Logger.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation

let kLogFileName = "log.txt"

var loggerIsInitialized = false

@objc extension FileManager {
    /// The path to the currently used logging directory.
    public var logDir: URL {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = documentDir.appendingPathComponent("logs")
        if !self.createFolder(atUrl: logsDir) {
            logInfo("Logger: Only stdout logs are available.")
        }
        return logsDir
    }

    /// The path to the currently used log file.
    public var logfile: URL {
        return self.logDir.appendingPathComponent(kLogFileName)
    }

    /// Create a logger instance for stdout and the log file.
    public func initLogger() {
        guard !loggerIsInitialized else { return }

        loggerIsInitialized = true

        let logPath = FileManager.default.logfile.path

        // Init the logger
        logger_autoFlush(5000) // Flush every 5 seconds
        logger_initConsoleLogger(nil)
        logInfo("Logger: Using log file: \(logPath)")
        logger_initFileLogger(logPath, 1024*1024*5, 5) // 5MB limit per file
    }

    /// Delete all old, rotated backup files.
    @discardableResult
    public func clearBackupLogs() -> Bool {
        var success = true
        let enumerator = self.enumerator(atPath: self.logDir.path)
        while let file = enumerator?.nextObject() as? String {
            // Skip the current log
            if file == kLogFileName {
                continue
            }

            do {
                try self.removeItem(atPath: file)
            } catch {
                logError("Logger: Could not delete log \(file). Reason: \(error.localizedDescription)")
                success = false
            }
        }
        return success
    }
}
