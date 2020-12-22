//
//  NSWindow+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import AppKit

extension NSWindow {
    /// Show error sheet for this window.
    /// - Parameter title: alert title
    /// - Parameter message: alert message
    /// - Return: the modal response
    @discardableResult
    func showError(_ title: String, message: String) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.alertStyle = .critical
        return alert.runModal()
    }

    /// Show the open panel to select a file.
    /// - Parameter title: panel title
    /// - Parameter extensions: permitted file extensions
    /// - Return: the modal response
    @discardableResult
    func showOpenPanel(_ tilte: String, extensions: [String]) -> (NSApplication.ModalResponse, URL?) {
        let dialog = NSOpenPanel()
        dialog.title                   = title
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = extensions
        return (dialog.runModal(), dialog.url)
    }
}
