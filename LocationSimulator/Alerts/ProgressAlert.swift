//
//  ProgressViewAlert.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

/// Alert view which manages and shows the download progress for the developer disk images.
class ProgressAlert: NSAlert {
    public var progressView: ProgressView? {
        return self.accessoryView as? ProgressView
    }

    override init() {
        super.init()

        self.messageText = NSLocalizedString("PROGRESS", comment: "")
        self.informativeText = NSLocalizedString("", comment: "")
        self.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        self.alertStyle = .informational

        self.accessoryView = ProgressView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    }

    /// Prepare the download of the developer disk images.
    /// - Parameter os: the os type to download the image for
    /// - Parameter iOSVersion: the version number to download the image for
    /// - Return: true if the download was started, false otherwise
    @discardableResult
    public func prepareDownload(os: String, iOSVersion: String) -> Bool {
        return self.progressView?.prepareDownload(os: os, iOSVersion: iOSVersion) ?? false
    }

    /// Start downloading the developer disk images.
    /// - Return: true if the download was started, false otherwise
    @discardableResult
    public func startDownload() -> Bool {
        return self.progressView?.startDownload() ?? false
    }

    /// Start download the developer disk images.
    /// - Return: true if the download was canceled, false otherwise
    @discardableResult
    public func cancelDownload() -> Bool {
        return self.progressView?.cancelDownload() ?? false
    }

    override func beginSheetModal(for sheetWindow: NSWindow,
                                  completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        super.beginSheetModal(for: sheetWindow) { [unowned self] response in
            switch response {
            // User canceled
            case .alertFirstButtonReturn:
                self.cancelDownload()
                handler?(.cancel)
            // Success or Download failed
            case .OK, .cancel :
                handler?(response)
            default:
                break
            }
        }
    }
}
