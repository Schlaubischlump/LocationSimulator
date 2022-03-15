//
//  CoordinateSelectionAlert.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import CoreLocation

typealias CoordinateSelectionCompletionHandler = ((NSApplication.ModalResponse, CLLocationCoordinate2D?) -> Void)

/// Extend the response for a more readable format.
extension NSApplication.ModalResponse {
    static let teleport = NSApplication.ModalResponse(10000)
    static let navigate = NSApplication.ModalResponse(10001)
}

/// Alert view which manages and shows the coordinate selection to the user.
class CoordinateSelectionAlert: NSAlert {

    /// True if the navigation button is shows, false otherwise.
    public private(set) var showsNavigationButton: Bool = false

    /// True if the user can input coordinates, false otherwise.
    public private(set) var showsUserInput: Bool = false

    public var coordinateSelectionView: CoordinateSelectionView? {
        return self.accessoryView as? CoordinateSelectionView
    }

    /// Default constructor.
    /// - Parameter showNavigate: true to show the navigation button or false to hide it.
    init(showNavigationButton: Bool, showUserInput: Bool) {
        super.init()

        self.showsNavigationButton = showNavigationButton
        self.showsUserInput = showUserInput

        self.messageText = "DESTINATION".localized
        self.informativeText = "TELEPORT_OR_NAVIGATE_MSG".localized
        self.addButton(withTitle: "CANCEL".localized)
        if showNavigationButton {
            self.addButton(withTitle: "NAVIGATE".localized)
        }
        self.addButton(withTitle: "TELEPORT".localized)
        self.alertStyle = .informational

        if showsUserInput {
            let coordView = CoordinateSelectionView(frame: CGRect(x: 0, y: 0, width: 330, height: 40))
            // Check if we find coordinates in the pasteboard to insert
            if let (lat, long) = NSPasteboard.general.parseFirstItemAsCoordinates() {
                coordView.lat = lat
                coordView.long = long
            }

            self.accessoryView = coordView
        }
    }

    override func beginSheetModal(for sheetWindow: NSWindow,
                                  completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        fatalError("Do not use this function. Use the two argument implementation instead.")
    }

    /// Ask the user to confirm the teleportation.
    /// - Return: true if the teleportation should be performed, false otherwise.
    private func confirmTeleportation(for sheetWindow: NSWindow) -> Bool {
        if UserDefaults.standard.confirmTeleportation {
            return sheetWindow.showConfirmation("CONFIRM_TELEPORT", message: "CONFIRM_TELEPORT_MSG") == .OK
        }
        // The user does not wish to be asked about the teleportation.
        return true
    }

    /// Implementation to handle the response more nicely and add a second argument.
    func beginSheetModal(for sheetWindow: NSWindow,
                         completionHandler handler: CoordinateSelectionCompletionHandler? = nil) {
        // If we don't need user input and we do not have the option to navigate we can only teleport. No need to ask.
        if !self.showsUserInput && !self.showsNavigationButton {
            let coord = self.coordinateSelectionView?.getCoordinates()
            handler?(self.confirmTeleportation(for: sheetWindow) ? .teleport : .cancel, coord)
            return
        }

        // Show the actual coordinate selection.
        super.beginSheetModal(for: sheetWindow) { [unowned self] response in
            // Get the user entered coordinates
            let coord = self.coordinateSelectionView?.getCoordinates()
            switch response {
            // User canceled
            case .alertFirstButtonReturn: handler?(.cancel, coord)
            // Navigate or teleport depending on whether navigate is available
            case .alertSecondButtonReturn: handler?( self.showsNavigationButton ? .navigate : .teleport, coord)
            // Teleport
            case .alertThirdButtonReturn:
                // Check if we need to confirm the teleportation.
                handler?(self.confirmTeleportation(for: sheetWindow) ? .teleport : .cancel, coord)
            default: break
            }
        }
    }
}
