//
//  DeveloperDiskImage.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.08.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CLogger

public class DeveloperDiskImage {
    typealias Platform = String
    typealias Version = String
    typealias FileType = String
    typealias JSonType = [Platform: [Version: [FileType: [String]]]]

    enum File: Hashable, CustomStringConvertible {
        static func allCases(forOS os: String, version: String) -> [DeveloperDiskImage.File] {
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

        var url: URL? {
            let fileManager = FileManager.default
            switch self {
            case .image(let os, let version):
                return fileManager.getDeveloperDiskImage(os: os, version: version)
            case .signature(let os, let version):
                return fileManager.getDeveloperDiskImageSignature(os: os, version: version)
            case .trustcache(let os, let version):
                return fileManager.getDeveloperDiskImageTrustcache(os: os, version: version)
            case .buildManifest(let os, let version):
                return fileManager.getDeveloperDiskImageBuildManifest(os: os, version: version)
            }
        }

        var description: String {
            switch self {
            case .image(let os, let version): return "image_\(os)_\(version)"
            case .signature(let os, let version): return "signature_\(os)_\(version)"
            case .trustcache(let os, let version): return "trustcache_\(os)_\(version)"
            case .buildManifest(let os, let version): return "buildmanifest_\(os)_\(version)"
            }
        }
    }

    let os: String
    let version: String
    private static var backupIDs: [File: UUID] = [:]

    fileprivate var backupFiles: [(originalFile: URL, backupFile: URL)] {
        let fileManager = FileManager.default
        let tmpDir = fileManager.temporaryDirectory

        return File.allCases(forOS: self.os, version: self.version).compactMap {
            if let originalFile = $0.url {
                let backupFile = tmpDir.appendingPathComponent(self.backupID(forKey: $0).uuidString)
                return (originalFile, backupFile)
            }
            return nil
        }
    }

    var downloadLinks: [File: URL] {
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

    init(os: String, version: String) {
        self.os = os
        self.version = version
    }

    private func backupID(forKey key: File) -> UUID {
        if let id = DeveloperDiskImage.backupIDs[key] {
            return id
        }
        let id = UUID()
        DeveloperDiskImage.backupIDs[key] = id
        return id
    }

    /// Parse the DeveloperDiskImages.json and return the download links for all DeveloperDiskImages files for every
    /// iOS version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter version: version string for the iOS device, e.g. 13.0
    /// - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
    static func getDownloadLinks(os: String, version: String) -> [String: [URL]] {
        // Check if the plist file and the platform inside the file can be found.
        let manager = FileManager.default
        guard let jsonPath = manager.developerDiskImageDownloadDefinitionsFile,
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

    func backup() throws {
        let fileManager = FileManager.default
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

    func restore() throws {
        let fileManager = FileManager.default
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
