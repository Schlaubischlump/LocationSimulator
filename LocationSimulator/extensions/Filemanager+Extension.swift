//
//  Filemanager+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 20.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation

extension FileManager {

    /**
     Create a new folder at the specified URL.
     - Return: True if the folder was created or did already exist. False otherwise.
     */
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

    /**
     Get the path to the systems Application Support directory for this application.
     - Parameter create: True: try to create the folder if it does not exist, False: just return the path
     - Return: Path to the Application Support directory for this application.
     */
    func getAppSupportDirectory(create: Bool = false) -> URL? {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let userAppSupportDir = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appSupportDir = userAppSupportDir.appendingPathComponent(appName, isDirectory: true)

        // if the folder does not exist yet => create it
        if !create || self.createFolder(atUrl: appSupportDir) {
            return appSupportDir
        }

        return appSupportDir
    }

    /**
     Get the path to the DeveloperDiskImage.dmg inside the applications Support directory.
     - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
     - Return: path to DeveloperDiskImage.dmg
     */
    func getDeveloperDiskImage(iOSVersion: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg
        if let url = self.getAppSupportDirectory(create: true) {
            let versionFolder: URL = url.appendingPathComponent(iOSVersion)
            if self.createFolder(atUrl: versionFolder) {
                return versionFolder.appendingPathComponent("DeveloperDiskImage.dmg")
            }
        }
        return nil
    }

    /**
     Get the path to the DeveloperDiskImage.dmg.signature inside the applications Support directory.
     - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
     - Return: path to DeveloperDiskImage.dmg.signature
     */
    func getDeveloperDiskImageSignature(iOSVersion: String) -> URL? {
        // get the path to the DeveloperDiskImage.dmg.signature
        if let devDisk: URL = self.getDeveloperDiskImage(iOSVersion: iOSVersion) {
            return URL(fileURLWithPath: devDisk.path + ".signature")
        }
        return nil
    }

    /**
     Parse the DeveloperDiskImages.plist inside the applications bundle and return the download links
     for all DeveloperDiskImages files for every iOS version.
     - Parameter iOSVersion: version string for the iOS device, e.g. 13.0
     - Return: [[DeveloperDiskImage.dmg download links], [DeveloperDiskImage.dmg.signature download links]]
     */
    func getDeveloperDiskImageDownloadLinks(iOSVersion: String) -> ([URL], [URL]) {
        if let plistPath = Bundle.main.path(forResource: "DeveloperDiskImages", ofType: "plist")
        {
            let downloadLinksPlist = NSDictionary(contentsOfFile: plistPath)
            if let downloadLinks: NSDictionary = downloadLinksPlist?[iOSVersion] as? NSDictionary,
                let dmgLinks = downloadLinks["Image"] as? [String], let signLinks = downloadLinks["Signature"] as? [String] {
                return (dmgLinks.map { URL(string: $0)! }, signLinks.map { URL(string: $0)! })
            }
        }
        return ([], [])
    }
}
