//
//  FileManager+Logger.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation

var loggerIsInitialized = false

let kLogFileName = "log.txt"

@objc public extension FileManager {
    /// Create a new folder at the specified URL.
    /// - Return: True if the folder was created or did already exist. False otherwise.
    func createFolder(atUrl url: URL) -> Bool {
        // if the folder does exist just return
        var isDir: ObjCBool = false
        if self.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue {
            return true
        }
        // try to create the directory
        do {
            try self.createDirectory(at: url, withIntermediateDirectories: false, attributes: .none)
        } catch {
            logError("Folder \(url.path): Could not be created. Reason: \(error.localizedDescription)")
            return false
        }
        return true
    }

    /// The path to the currently used logging directory.
    var logDir: URL {
        let fileManager = FileManager.default
        let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = documentDir.appendingPathComponent("logs")
        if !fileManager.createFolder(atUrl: logsDir) {
            logInfo("Logger: Only stdout logs are available.")
        }
        return logsDir
    }

    /// The path to the currently used log file.
    var logFile: URL {
        return self.logDir.appendingPathComponent(kLogFileName)
    }

    func initLogger() {
        guard !loggerIsInitialized else { return }

        loggerIsInitialized = true

        // Init the console logger
        logger_autoFlush(5000) // Flush every 5 seconds
        logger_initConsoleLogger(nil)

        // Init the file logger
        let logPath = FileManager.default.logFile.path
        logInfo("Logger: Using log file: \(logPath)")
        logger_initFileLogger(logPath, 1024*1024*5, 5) // 5MB limit per file
    }

    /// Delete all old, rotated backup files.
    @discardableResult
    func deleteBackupLogs() -> Bool {
        let fileManager = FileManager.default

        var success = true
        let enumerator = fileManager.enumerator(atPath: fileManager.logDir.path)
        while let file = enumerator?.nextObject() as? String {
            // Skip the current log
            if file == kLogFileName {
                continue
            }

            do {
                try fileManager.removeItem(atPath: file)
            } catch {
                logError("Logger: Could not delete log \(file). Reason: \(error.localizedDescription)")
                success = false
            }
        }
        return success
    }

    /// Delete the currently active log.
    func deleteActiveLog() -> Bool {
        return logger_clear() == 0
    }
}
