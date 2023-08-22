//
//  Filemanager+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit.NSWorkspace
import CLogger

enum FileError: Error {
    case invalidPermission
    case notFound
}

extension FileManager {

    public var isSupportDirectoryWriteable: Bool {
        let supportDir = self.getSupportDirectory(create: false)

        let startAccess = supportDir?.startAccessingSecurityScopedResource() ?? false

        defer {
            if startAccess {
                supportDir?.stopAccessingSecurityScopedResource()
            }
        }

        if let path = supportDir?.path {
            return self.isWritableFile(atPath: path)
        }
        return false
    }

    public var usesCustomSupportDirectory: Bool {
        let customSupportDirEnabled = UserDefaults.standard.customSupportDirectoryEnabled
        let customSupportDir = UserDefaults.standard.customSupportDirectory
        return customSupportDirEnabled && customSupportDir != nil
    }

    /// Get the path to the systems Application Support directory for this application.
    /// - Parameter create: True: try to create the folder if it does not exist, False: just return the path
    /// - Return: Path to the Application Support directory for this application.
    func getAppSupportDirectory(create: Bool = false) -> URL? {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else { return nil }
        let userAppSupportDir = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appSupportDir = userAppSupportDir.appendingPathComponent(appName, isDirectory: true)

        // if the folder does not exist yet => create it
        if !create || self.createFolder(atUrl: appSupportDir) {
            return appSupportDir
        }
        return appSupportDir
    }

    /// Get the path to the user defined support directory or the system support directory if the user has not defined
    /// a custom path.
    /// - Parameter create: True: try to create the folder if it does not exist, False: just return the path
    /// - Return: Path to the support directory
    func getSupportDirectory(create: Bool, subdirs: String...) -> URL? {
        let customSupportDirEnabled = UserDefaults.standard.customSupportDirectoryEnabled
        let customSupportDir = UserDefaults.standard.customSupportDirectory
        if customSupportDirEnabled, let url = customSupportDir {
            if create {
                let startAccess = url.startAccessingSecurityScopedResource()
                let urlWithSubdirs = url.appendPaths(paths: subdirs)
                let success = self.createFolder(atUrl: urlWithSubdirs, withIntermediateDirectories: true)
                if startAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                return success ? urlWithSubdirs : nil
            }
            return url.appendPaths(paths: subdirs)
        }
        guard let supportDir = self.getAppSupportDirectory(create: create) else {
            return nil
        }
        return supportDir.appendPaths(paths: subdirs)
    }

    /// Show a file in the finder.
    public func showFileInFinder(_ url: URL) {
        guard let supportDir = self.getSupportDirectory(create: true) else { return }

        let startAccess = supportDir.startAccessingSecurityScopedResource()
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        if startAccess {
            supportDir.stopAccessingSecurityScopedResource()
        }
    }

    /// Execute a code block with elevated access privilege level. This is required if the user selected a custom
    /// directory for his DeveloperDiskImages. If the default path is used, this is a no-op.
    /// - Parameter handler: the code block to execute
    @discardableResult
    public func accessSupportDirectory<T>(_ handler: () throws -> T) throws -> T {
        guard let supportDir = self.getSupportDirectory(create: true) else {
            throw FileError.invalidPermission
        }

        let startAccess = supportDir.startAccessingSecurityScopedResource()
        defer {
            if startAccess {
                supportDir.stopAccessingSecurityScopedResource()
            }
        }

        return try handler()
    }

    /// Start elevating the access privilege level. This is required if the user selected a custom directory for his
    /// DeveloperDiskImages. If the default path is used, this is a no-op.
    /// - Return: True on success, False otherwise
    @discardableResult
    public func startAccessingSupportDirectory() -> Bool {
        guard let supportDir = self.getSupportDirectory(create: true) else { return false }
        return supportDir.startAccessingSecurityScopedResource()
    }

    /// Stop elevating the access privilege level.
    public func stopAccessingSupportDirectory() {
        guard let supportDir = self.getSupportDirectory(create: true) else { return }
        return supportDir.stopAccessingSecurityScopedResource()
    }
}
