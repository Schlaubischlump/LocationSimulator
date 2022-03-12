//
//  Filemanager+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit.NSWorkspace

public struct BackupToken {
    let os: String
    let version: String
    let devDiskId: UUID
    let devSignId: UUID
}

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

    /// Create a new folder at the specified URL.
    /// - Return: True if the folder was created or did already exist. False otherwise.
    public func createFolder(atUrl url: URL) -> Bool {
        // if the folder does exist just return
        var isDir: ObjCBool = false
        if self.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue {
            return true
        }
        // try to create the directory
        do {
            try self.createDirectory(at: url, withIntermediateDirectories: false, attributes: .none)
        } catch {
            return false
        }
        return true
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
        guard let url = self.getSupportDirectory(create: true) else { return [] }

        let startAccess = url.startAccessingSecurityScopedResource()

        defer {
            if startAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let osFolder: URL = url.appendingPathComponent(os)
        guard let content = try? self.contentsOfDirectory(at: osFolder, includingPropertiesForKeys: [.isDirectoryKey],
                                                          options: [.skipsHiddenFiles]) else {
            return []
        }

        return content.compactMap { url in
            if let value = try? url.resourceValues(forKeys: [.isDirectoryKey]), value.isDirectory ?? false {
                let devDisk = url.appendingPathComponent("DeveloperDiskImage.dmg")
                let devDiskSig = url.appendingPathComponent("DeveloperDiskImage.dmg.signature")
                if self.fileExists(atPath: devDisk.path) && self.fileExists(atPath: devDiskSig.path) {
                    return url.lastPathComponent
                }
                return nil
            }
            return nil
        }.filter { $0.isVersionString }.sorted { $0 > $1 }
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

    /// Backup the DeveloperDiskImage.dmg and DeveloperDiskImage.dmg.signature files to a temporary directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: BackupToken with a unique id for each backuped file
    public func backupSupportFiles(os: String, version: String) throws -> BackupToken? {
        guard let devDisk = self.getDeveloperDiskImage(os: os, version: version),
              let devDiskSig = self.getDeveloperDiskImageSignature(os: os, version: version) else { return nil }

        let token = BackupToken(os: os, version: version, devDiskId: UUID(), devSignId: UUID())

        let tmpDir = self.temporaryDirectory
        let devDiskTmp = tmpDir.appendingPathComponent(token.devDiskId.uuidString)
        let devDiskSigTmp = tmpDir.appendingPathComponent(token.devSignId.uuidString)

        try self.accessSupportDirectory {
            try self.copyItem(at: devDisk, to: devDiskTmp)
            try self.copyItem(at: devDiskSig, to: devDiskSigTmp)
        }

        return token
    }

    /// Restore the DeveloperDiskImage.dmg and DeveloperDiskImage.dmg.signature files from a temporary directory.
    /// - Parameter token: the backup token
    public func restoreSupportFiles(token: BackupToken) throws {
        guard let devDisk = self.getDeveloperDiskImage(os: token.os, version: token.version),
              let devDiskSig = self.getDeveloperDiskImageSignature(os: token.os, version: token.version) else {
                  throw FileError.invalidPermission
              }

        let tmpDir = self.temporaryDirectory
        let devDiskTmp = tmpDir.appendingPathComponent(token.devDiskId.uuidString)
        let devDiskSigTmp = tmpDir.appendingPathComponent(token.devSignId.uuidString)

        var isDir: ObjCBool = false
        let hasDevDiskTmp = self.fileExists(atPath: devDiskTmp.path, isDirectory: &isDir) && !isDir.boolValue
        let hasDevDiskSignTmp = self.fileExists(atPath: devDiskSigTmp.path, isDirectory: &isDir) && !isDir.boolValue

        if !hasDevDiskTmp || !hasDevDiskSignTmp {
            throw FileError.notFound
        }

        try self.accessSupportDirectory {
            _ = try self.replaceItemAt(devDisk, withItemAt: devDiskTmp)
            _ = try self.replaceItemAt(devDiskSig, withItemAt: devDiskSigTmp)
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

    /// Parse the DeveloperDiskImages.plist inside the applications bundle and return the download links for all
    /// DeveloperDiskImages files for every iOS version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
    public func getDeveloperDiskImageDownloadLinks(os: String, version: String) -> ([URL], [URL]) {
        // Check if the plist file and the platform inside the file can be found.
        guard let plistPath = Bundle.main.path(forResource: "DeveloperDiskImages", ofType: "plist"),
              let downloadLinksPlist = NSDictionary(contentsOfFile: plistPath),
              let downloadLinksForOS: NSDictionary = downloadLinksPlist[os] as? NSDictionary else {
            return ([], [])
        }

        // Check if a specific download URL is available.
        if let downloadLinks: NSDictionary = downloadLinksForOS[version] as? NSDictionary,
           let dmgLinks = downloadLinks["Image"] as? [String],
           let signLinks = downloadLinks["Signature"] as? [String] {
            return (dmgLinks.map { URL(string: $0)! }, signLinks.map { URL(string: $0)! })
        }

        // Try to use the fallback links if no direct links were found.
        if let fallbackLinks: NSDictionary = downloadLinksForOS["Fallback"] as? NSDictionary,
           let dmgLinks = fallbackLinks["Image"] as? [String],
           let signLinks = fallbackLinks["Signature"] as? [String] {
            return (dmgLinks.map { URL(string: String(format: $0, version))! },
                    signLinks.map { URL(string: String(format: $0, version))! })
        }

        // We did not find any download link.
        return ([], [])
    }

    /// Get all dependeny names with their corresponding license text in a dictionary.
    /// - Return: license name with the corresponding license text as Dictionary
    public func getLicenses() -> [String: String] {
        if let plistPath = Bundle.main.path(forResource: "Licenses", ofType: "plist") {
            let licenseDict = NSDictionary(contentsOfFile: plistPath) as? [String: String]
            return licenseDict ?? [:]
        }
        return [:]
    }
}

// MARK: - Logger

let kLogFileName = "log.txt"

extension FileManager {
    public var logDir: URL {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = documentDir.appendingPathComponent("logs")
        if !self.createFolder(atUrl: logsDir) {
            logError("Could not create 'logs' directory. Only stdout logs are available.")
        }
        return logsDir
    }

    public var logfile: URL {
        return self.logDir.appendingPathComponent(kLogFileName)
    }

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
                logError("Could not delete logs. Reason: \(error.localizedDescription)")
                success = false
            }
        }
        return success
    }
}
