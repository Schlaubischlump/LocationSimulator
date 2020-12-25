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
    //@discardableResult
    func showError(_ title: String, message: String, localize: Bool = true) {// -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = localize ? NSLocalizedString(title, comment: "") : title
        alert.informativeText = localize ? NSLocalizedString(message, comment: "") : message
        alert.alertStyle = .critical
        // Calling runModal will block the .common runloop. This runloop is used by DispatchQueue.main.async. This
        // function is used by MKMapView to load the map. That means, calling runModal, blocks the MapView from loading
        // the map. Since we do not need the modal response, we just leave it out and present the view as sheet instead.
        //return alert.runModal()
        alert.beginSheetModal(for: self)
    }

    /// Ask for confirmation.
    func showConfirmation(_ title: String, message: String, localize: Bool = true) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = localize ? NSLocalizedString(title, comment: "") : title
        alert.informativeText = localize ? NSLocalizedString(message, comment: "") : message
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
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
