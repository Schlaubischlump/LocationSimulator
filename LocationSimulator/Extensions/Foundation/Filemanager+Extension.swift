//
//  Filemanager+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation

extension FileManager {
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
            return false
        }
        return true
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

    /// Get the version number for all avaiable versions downloaded for a platform.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Return: List with version numbers (e.g. [15.0, 15.1, 15.2])
    func getAvailableVersions(os: String) -> [String] {
        if let url = self.getAppSupportDirectory(create: true) {
            let osFolder: URL = url.appendingPathComponent(os)
            if let content = try? self.contentsOfDirectory(at: osFolder,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: [.skipsHiddenFiles, .producesRelativePathURLs]) {
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
        }
        return []
    }

    /// Remove the downlaoded DeveloperDiskImage and the corresponding signature file for a specific version.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
    /// - Return: true on success, false otherwise
    func removeDownload(os: String, iOSVersion: String) -> Bool {
        if let url = self.getAppSupportDirectory(create: false) {
            let osFolder: URL = url.appendingPathComponent(os)
            let versionFolder: URL = osFolder.appendingPathComponent(iOSVersion)
            do {
                try self.removeItem(at: versionFolder)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    /// Get the path to the DeveloperDiskImage.dmg inside the applications Support directory.
    /// - Parameter os: the platform or operating system e.g. iPhone OS
    /// - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg
    func getDeveloperDiskImage(os: String, iOSVersion: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg
        if let url = self.getAppSupportDirectory(create: true) {
            let osFolder: URL = url.appendingPathComponent(os)
            let versionFolder: URL = osFolder.appendingPathComponent(iOSVersion)
            if self.createFolder(atUrl: osFolder) && self.createFolder(atUrl: versionFolder) {
                return versionFolder.appendingPathComponent("DeveloperDiskImage.dmg")
            }
        }
        return nil
    }

    /// Get the path to the DeveloperDiskImage.dmg.signature inside the applications Support directory.
    /// - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
    /// - Return: path to DeveloperDiskImage.dmg.signature
    func getDeveloperDiskImageSignature(os: String, iOSVersion: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg.signature
        if let devDisk: URL = self.getDeveloperDiskImage(os: os, iOSVersion: iOSVersion) {
            return URL(fileURLWithPath: devDisk.path + ".signature")
        }
        return nil
    }

    /// Parse the DeveloperDiskImages.plist inside the applications bundle and return the download links for all
    /// DeveloperDiskImages files for every iOS version.
    /// - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
    /// - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
    func getDeveloperDiskImageDownloadLinks(os: String, version: String) -> ([URL], [URL]) {
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
    func getLicenses() -> [String: String] {
        if let plistPath = Bundle.main.path(forResource: "Licenses", ofType: "plist") {
            let licenseDict = NSDictionary(contentsOfFile: plistPath) as? [String: String]
            return licenseDict ?? [:]
        }
        return [:]
    }
}
