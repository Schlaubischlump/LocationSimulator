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
    /// - Parameter localize: true to localize the title and message
    /// - Return: the modal response
    // @discardableResult
    func showError(_ title: String, message: String, localize: Bool = true) {// -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = localize ? title.localized : title
        alert.informativeText = localize ? message.localized : message
        alert.alertStyle = .critical
        // Calling runModal will block the .common runloop. This runloop is used by DispatchQueue.main.async. This
        // function is used by MKMapView to load the map. That means, calling runModal, blocks the MapView from loading
        // the map. Since we do not need the modal response, we just leave it out and present the view as sheet instead.
        // return alert.runModal()
        alert.beginSheetModal(for: self)
    }

    /// Ask for confirmation.
    func showConfirmation(_ title: String, message: String, localize: Bool = true) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = localize ? title.localized : title
        alert.informativeText = localize ? message.localized : message
        alert.addButton(withTitle: "CANCEL".localized)
        alert.addButton(withTitle: "OK".localized)
        alert.alertStyle = .informational
        switch alert.runModal() {
        case .alertFirstButtonReturn:  return .cancel
        case .alertSecondButtonReturn: return .OK
        default: return .cancel
        }
    }

    /// Show the open panel to select a file.
    /// - Parameter title: panel title
    /// - Parameter extensions: permitted file extensions
    /// - Return: the modal response
    @discardableResult
    func showOpenPanel(_ tilte: String, extensions: [String], localize: Bool = true)
    -> (NSApplication.ModalResponse, URL?) {
        let dialog = NSOpenPanel()
        dialog.title                   = localize ? title.localized : title
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = extensions
        return (dialog.runModal(), dialog.url)
    }
}
