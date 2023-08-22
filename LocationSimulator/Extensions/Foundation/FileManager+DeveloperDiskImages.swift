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

    public var developerDiskImageDownloadDefinitionsFile: URL? {
        // Note: Do not store this file in the custom support directory
        guard let supportDir = self.getAppSupportDirectory(create: true) else {
            return nil
        }
        return supportDir.appendingPathComponent("DeveloperDiskImages.json", isDirectory: false)
    }

    /// Get the path to the systems Application Support directory for this application.
    /// - Parameter create: True: try to create the folder if it does not exist, False: just return the path
    /// - Return: Path to the Application Support directory for this application.
    private func getAppSupportDirectory(create: Bool = false) -> URL? {
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
    public func getSupportDirectory(create: Bool) -> URL? {
        let customSupportDirEnabled = UserDefaults.standard.customSupportDirectoryEnabled
        let customSupportDir = UserDefaults.standard.customSupportDirectory
        if customSupportDirEnabled, let url = customSupportDir {
            if create {
                let startAccess = url.startAccessingSecurityScopedResource()
                let success = self.createFolder(atUrl: url)
                if startAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                return success ? url : nil
            }
            return url
        }
        return self.getAppSupportDirectory(create: create)
    }

    /// Get the version number for all avaiable versions downloaded for a platform.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Return: List with version numbers (e.g. [15.0, 15.1, 15.2])
    public func getAvailableVersions(os: String) -> [String] {
        guard let supportFolder = self.getSupportDirectory(create: true) else { return [] }

        let startAccess = supportFolder.startAccessingSecurityScopedResource()

        defer {
            if startAccess {
                supportFolder.stopAccessingSecurityScopedResource()
            }
        }

        let osFolder: URL = supportFolder.appendingPathComponent(os)
        let enumerator = self.enumerator(at: osFolder, includingPropertiesForKeys: [.isDirectoryKey],
                                         options: .skipsHiddenFiles, errorHandler: { url, error  in
            logError("DeveloperDiskImage directory \(url.path): Skipping. Reason: \(error.localizedDescription)")
            return true
        })

        return enumerator?.compactMap { url in
            guard let url = url as? URL else { return nil }

            if let value = try? url.resourceValues(forKeys: [.isDirectoryKey]), value.isDirectory ?? false {
                let devDisk = url.appendingPathComponent("DeveloperDiskImage.dmg")
                if self.fileExists(atPath: devDisk.path) {
                    return url.lastPathComponent
                } else {
                    logWarning("DeveloperDiskImage directory \(url.path): Skipping. Reason: Missing support files.")
                }
            }
            return nil
        }.filter { $0.isVersionString }.sorted { $0 > $1 } ?? []
    }

    /// Check if the DeveloperDiskImage.dmg and DeveloperDiskImage.dmg.signature for a specific platform and version
    /// has been downlaoded.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: true if the files have been download, false otherwise
    public func hasDownloadedSupportFiles(os: String, version: String) -> Bool {
        guard let devDisk = self.getDeveloperDiskImage(os: os, version: version),
              let devDiskSig = self.getDeveloperDiskImageSignature(os: os, version: version) else { return false }

        let startAccess = self.startAccessingSupportDirectory()
        defer {
            if startAccess {
                self.stopAccessingSupportDirectory()
            }
        }

        var isDir: ObjCBool = false
        let hasDevDisk = self.fileExists(atPath: devDisk.path, isDirectory: &isDir) && !isDir.boolValue
        let hasDevDiskSign = self.fileExists(atPath: devDiskSig.path, isDirectory: &isDir) && !isDir.boolValue
        return hasDevDisk && hasDevDiskSign
    }

    /// Remove the downlaoded DeveloperDiskImage and the corresponding signature file for a specific version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: true on success, false otherwise
    public func removeDownload(os: String, version: String) -> Bool {
        guard let url = self.getSupportDirectory(create: false) else { return false }

        let startAccess = url.startAccessingSecurityScopedResource()

        defer {
            if startAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let osFolder: URL = url.appendingPathComponent(os)
        let versionFolder: URL = osFolder.appendingPathComponent(version)
        do {
            try self.removeItem(at: versionFolder)
        } catch {
            let errorMsg = error.localizedDescription
            logError("DeveloperDiskImage directory \(versionFolder.path): Could not be deleted. Reason: \(errorMsg)")
            return false
        }

        return true
    }

    /// Get the path to the DeveloperDiskImage.dmg inside the applications Support directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg
    public func getDeveloperDiskImage(os: String, version: String) -> URL? {
        guard let url = self.getSupportDirectory(create: true) else { return nil }

        // get the path to the DeveloperDiskImage.dmg
        let osFolder: URL = url.appendingPathComponent(os)
        let versionFolder: URL = osFolder.appendingPathComponent(version)

        let startAccess = url.startAccessingSecurityScopedResource()

        defer {
            if startAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if self.createFolder(atUrl: osFolder) && self.createFolder(atUrl: versionFolder) {
            return versionFolder.appendingPathComponent("DeveloperDiskImage.dmg")
        }

        return nil
    }

    /// Get the path to the DeveloperDiskImage.dmg.signature inside the applications Support directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg.signature
    public func getDeveloperDiskImageSignature(os: String, version: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg.signature
        if let devDisk: URL = self.getDeveloperDiskImage(os: os, version: version) {
            return URL(fileURLWithPath: devDisk.path + ".signature")
        }
        return nil
    }

    /// Get the path to the DeveloperDiskImage.dmg.trustcache inside the applications Support directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg.signature
    public func getDeveloperDiskImageTrustcache(os: String, version: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg.trustcache
        if let devDisk: URL = self.getDeveloperDiskImage(os: os, version: version) {
            return URL(fileURLWithPath: devDisk.path + ".trustcache")
        }
        return nil
    }

    /// Get the path to the BuildManifest.plist inside the applications Support directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg.signature
    public func getDeveloperDiskImageBuildManifest(os: String, version: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg.trustcache
        if let versionFolder = self.getDeveloperDiskImage(os: os, version: version)?.deletingLastPathComponent() {
            return versionFolder.appendingPathComponent("BuildManifest.plist", isDirectory: false)
        }
        return nil
    }

    /// Backup the DeveloperDiskImage.dmg and DeveloperDiskImage.dmg.signature files to a temporary directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: BackupToken with a unique id for each backuped file
    public func backup(developerDiskImage: DeveloperDiskImage) throws {
        try self.accessSupportDirectory {
            try developerDiskImage.backup()
        }
    }

    /// Restore the DeveloperDiskImage.dmg and DeveloperDiskImage.dmg.signature files from a temporary directory.
    /// - Parameter token: the backup token
    public func restore(developerDiskImage: DeveloperDiskImage) throws {
        try self.accessSupportDirectory {
            try developerDiskImage.restore()
        }
    }

    /// Show the DeveloperDiskImage.dmg file in the finder.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    public func showDeveloperDiskImageInFinder(os: String, version: String) {
        guard let supportDir = self.getSupportDirectory(create: true) else { return }
        guard let url = self.getDeveloperDiskImage(os: os, version: version) else { return }

        let startAccess = supportDir.startAccessingSecurityScopedResource()
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        if startAccess {
            supportDir.stopAccessingSecurityScopedResource()
        }
    }

    /// Execute a code block with elevated access privilege level. This is required if the user selected a custom
    /// directory for his DeveloperDiskImages. If the default path is used, this is a no-op.
    /// - Parameter handler: the code block to execute
    public func accessSupportDirectory(_ handler: () throws -> Void) throws {
        guard let supportDir = self.getSupportDirectory(create: true) else { return }

        let startAccess = supportDir.startAccessingSecurityScopedResource()

        try handler()

        if startAccess {
            supportDir.stopAccessingSecurityScopedResource()
        }
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
