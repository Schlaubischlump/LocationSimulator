//
//  DeveloperDiskImage.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.08.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CLogger

@objc public class DeveloperDiskImage: NSObject {
    private typealias Platform = String
    private typealias Version = String
    private typealias FileKind = String
    private typealias JSonType = [Platform: [Version: [FileKind: [String]]]]

    /// Enum that represents the different kind of files a DeveloperDiskImage might include
    enum SupportFile: Hashable, CustomStringConvertible {
        static func allCases(forOS os: String, version: String) -> [DeveloperDiskImage.SupportFile] {
            return [
                .image(os: os, version: version),
                .signature(os: os, version: version),
                .trustcache(os: os, version: version),
                .buildManifest(os: os, version: version)
            ]
        }

        case image(os: String, version: String)
        case signature(os: String, version: String)
        case trustcache(os: String, version: String)
        case buildManifest(os: String, version: String)

        private var os: String {
            switch self {
            case .image(let osString, _):         return osString
            case .signature(let osString, _):     return osString
            case .trustcache(let osString, _):    return osString
            case .buildManifest(let osString, _): return osString
            }
        }

        private var version: String {
            switch self {
            case .image(_, let vesionString):         return vesionString
            case .signature(_, let vesionString):     return vesionString
            case .trustcache(_, let vesionString):    return vesionString
            case .buildManifest(_, let vesionString): return vesionString
            }
        }

        var url: URL? {
            let supportDir = DeveloperDiskImage.getSupportFilesDirectory(forOS: self.os, version: self.version)
            return supportDir?.appendingPathComponent(self.name, isDirectory: false)
        }

        var name: String {
            switch self {
            case .image:            return "DeveloperDiskImage.dmg"
            case .signature:        return "DeveloperDiskImage.dmg.signature"
            case .trustcache:       return "DeveloperDiskImage.dmg.trustcache"
            case .buildManifest:    return "BuildManifest.plist"
            }
        }

        var description: String {
            switch self {
            case .image(let os, let version):           return "image_\(os)_\(version)"
            case .signature(let os, let version):       return "signature_\(os)_\(version)"
            case .trustcache(let os, let version):      return "trustcache_\(os)_\(version)"
            case .buildManifest(let os, let version):   return "buildmanifest_\(os)_\(version)"
            }
        }
    }

    let os: String
    let version: String

    init(os: String, version: String) {
        self.os = os
        self.version = version
    }

    // MARK: - Download links

    /// Path to the json file that stores the download links for all DeveloperDiskImages.
    static var downloadDefinitionsFile: URL? {
        guard let appSupportDir = FileManager.default.getAppSupportDirectory(create: true) else {
            return nil
        }
        return appSupportDir.appendingPathComponent("DeveloperDiskImages.json", isDirectory: false)
    }

    /// True if all support files for a personalized DeveloperDiskImage are downloaded.
    var hasDownloadedPersonalizedImageFiles: Bool {
        let fileTypes = Set(self.supportFiles.keys)
        return fileTypes == Set([
            .image(os: self.os, version: self.version),
            .trustcache(os: self.os, version: self.version),
            .buildManifest(os: self.os, version: self.version)
        ])
    }

    /// True if all support files for a normal DeveloperDiskImage are downloaded.
    var hasDownloadedImageFiles: Bool {
        let fileTypes = Set(self.supportFiles.keys)
        return fileTypes == Set([
            .image(os: self.os, version: self.version),
            .signature(os: self.os, version: self.version)
        ])
    }

    var isDownloaded: Bool {
        return self.hasDownloadedPersonalizedImageFiles || self.hasDownloadedImageFiles
    }

    /// All download links for this DeveloperDiskImage.
    var downloadLinks: [SupportFile: URL] {
        let links = DeveloperDiskImage.getDownloadLinks(os: self.os, version: self.version)

        if let diskLinks = links["Image"],
            let signLinks = links["Signature"],
            !diskLinks.isEmpty && !signLinks.isEmpty {
            return [
                .image(os: self.os, version: self.version): diskLinks[0],
                .signature(os: self.os, version: self.version): signLinks[0]
            ]
        } else if let diskLinks = links["Image"],
                    let trustcacheLinks = links["Trustcache"],
                    let buildManifestLinks = links["BuildManifest"],
                    !diskLinks.isEmpty && !trustcacheLinks.isEmpty && !buildManifestLinks.isEmpty {
            return [
                .image(os: self.os, version: self.version): diskLinks[0],
                .trustcache(os: self.os, version: self.version): trustcacheLinks[0],
                .buildManifest(os: self.os, version: self.version): buildManifestLinks[0]
            ]
        }
        return [:]
    }

    /// Parse the DeveloperDiskImages.json and return the download links for all DeveloperDiskImages files for every
    /// iOS version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
    static func getDownloadLinks(os: String, version: String) -> [String: [URL]] {
        // Check if the plist file and the platform inside the file can be found
        guard let jsonPath = DeveloperDiskImage.downloadDefinitionsFile,
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

    // MARK: - Support Files

    /// All support files that belong to this DeveloperDiskImage.
    var supportFiles: [SupportFile: URL] {
        var isDir: ObjCBool = false
        let fileManager = FileManager.default

        let existingFiles: [(SupportFile, URL)]? = try? fileManager.accessSupportDirectory {
            let fileTypes = SupportFile.allCases(forOS: self.os, version: self.version)
            return fileTypes.compactMap { (fileType: SupportFile) in
                guard let url = fileType.url else {
                    return nil
                }
                guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue else {
                    return nil
                }
                return (fileType, url)
            }
        }
        return Dictionary(uniqueKeysWithValues: existingFiles ?? [])
    }

    private static func getSupportFilesDirectory(forOS os: String, version: String) -> URL? {
        return FileManager.default.getSupportDirectory(create: true, subdirs: os, version)
    }

    /// Get the version number for all avaiable versions downloaded for a platform.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Return: List with version numbers (e.g. [15.0, 15.1, 15.2])
    static func getAvailableVersions(forOS os: String) -> [String] {
        let fileManager = FileManager.default

        guard let supportFolder = fileManager.getSupportDirectory(create: true) else {
            return []
        }

        let startAccess = supportFolder.startAccessingSecurityScopedResource()

        defer {
            if startAccess {
                supportFolder.stopAccessingSecurityScopedResource()
            }
        }

        let osFolder: URL = supportFolder.appendingPathComponent(os)
        let urls = try? fileManager.contentsOfDirectory(at: osFolder,
                                                   includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                                                   options: .skipsHiddenFiles)

        return (urls ?? []).compactMap { url in
            let values: URLResourceValues? = try? url.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
            let version = values?.name
            let isDir = values?.isDirectory ?? false

            guard isDir, let version = version, version.isVersionString else { return nil }
            return DeveloperDiskImage(os: os, version: version).isDownloaded ? version : nil

        }.sorted { $0 > $1 }
    }

    // MARK: - Read

    var imageFile: URL? {
        return self.supportFiles[.image(os: self.os, version: self.version)]
    }

    var signatureFile: URL? {
        return self.supportFiles[.signature(os: self.os, version: self.version)]
    }

    var trustcacheFile: URL? {
        return self.supportFiles[.trustcache(os: self.os, version: self.version)]
    }

    var buildManifestFile: URL? {
        return self.supportFiles[.buildManifest(os: self.os, version: self.version)]
    }

    // MARK: - Store

    private func store(_ file: SupportFile, fromFileURL: URL) throws -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard let url = file.url else {
            return false
        }
        try fileManager.accessSupportDirectory {
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue {
                try _ = fileManager.replaceItemAt(url, withItemAt: fromFileURL)
            } else {
                try fileManager.copyItem(at: fromFileURL, to: url)
            }
        }

        return true
    }

    @discardableResult
    func storeImage(_ file: URL) throws -> Bool {
        try self.store(.image(os: self.os, version: self.version), fromFileURL: file)
    }

    @discardableResult
    func storeSignature(_ file: URL) throws -> Bool {
        try self.store(.signature(os: self.os, version: self.version), fromFileURL: file)
    }

    @discardableResult
    func storeTrustcache(_ file: URL) throws -> Bool {
        try self.store(.trustcache(os: self.os, version: self.version), fromFileURL: file)
    }

    @discardableResult
    func storeBuildManifest(_ file: URL) throws -> Bool {
        try self.store(.buildManifest(os: self.os, version: self.version), fromFileURL: file)
    }

    // MARK: - Cleanup

    /// Remove the downlaoded support files for the DeveloperDiskImage.
    func removeDownload() -> Bool {
        let fileManager = FileManager.default
        guard let versionFolder = fileManager.getSupportDirectory(create: true, subdirs: self.os, self.version ) else {
            return false
        }

        return (try? fileManager.accessSupportDirectory {
            do {
                try fileManager.removeItem(at: versionFolder)
                return true
            } catch {
                let errorMsg = error.localizedDescription
                logError("DeveloperDiskImage directory \(versionFolder.path): Deletion failed. Reason: \(errorMsg)")
                return false
            }
        }) ?? false
    }

    // MARK: - Backup

    /// Iternal lazily filled list with ids used for backuping up files.
    /// This is static to guarantee that one instance of a DeveloperDiskaImage can call backup, while another instance
    /// can call restore.
    private static var backupIDs: [SupportFile: UUID] = [:]

    private var backupFiles: [(originalFile: URL, backupFile: URL)] {
        let fileManager = FileManager.default
        let tmpDir = fileManager.temporaryDirectory

        return SupportFile.allCases(forOS: self.os, version: self.version).compactMap {
            if let originalFile = $0.url {
                let backupFile = tmpDir.appendingPathComponent(self.backupID(forKey: $0).uuidString)
                return (originalFile, backupFile)
            }
            return nil
        }
    }

    /// Lazily create a new backup id if required.
    private func backupID(forKey key: SupportFile) -> UUID {
        if let id = DeveloperDiskImage.backupIDs[key] {
            return id
        }
        let id = UUID()
        DeveloperDiskImage.backupIDs[key] = id
        return id
    }

    func backup() throws {
        let fileManager = FileManager.default
        try fileManager.accessSupportDirectory {
            try self.backupFiles.forEach { (originalFile, backupFile) in
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: originalFile.path, isDirectory: &isDir) && !isDir.boolValue {
                    if fileManager.fileExists(atPath: backupFile.path, isDirectory: &isDir) && !isDir.boolValue {
                        // Replace existing backup files
                        try _ = fileManager.replaceItemAt(originalFile, withItemAt: backupFile)
                    } else {
                        try fileManager.copyItem(at: originalFile, to: backupFile)
                    }
                } else {
                    // Silently skip the file if it does not exist for this type of DeveloperDiskImage
                }
            }
        }
    }

    func restore() throws {
        let fileManager = FileManager.default
        try fileManager.accessSupportDirectory {
            var isDir: ObjCBool = false
            try self.backupFiles.forEach { (originalFile, backupFile) in
                let hasFile = fileManager.fileExists(atPath: originalFile.path, isDirectory: &isDir) && !isDir.boolValue
                if !hasFile {
                    throw FileError.notFound
                }
                _ = try fileManager.replaceItemAt(originalFile, withItemAt: backupFile)
            }
        }
    }
}
