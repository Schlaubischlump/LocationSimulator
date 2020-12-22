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
    init(showNavigationButton: Bool, showsUserInput: Bool) {
        super.init()

        self.showsNavigationButton = showNavigationButton
        self.showsUserInput = showsUserInput

        self.messageText = NSLocalizedString("DESTINATION", comment: "")
        self.informativeText = NSLocalizedString("TELEPORT_OR_NAVIGATE_MSG", comment: "")
        self.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        if showNavigationButton {
            self.addButton(withTitle: NSLocalizedString("NAVIGATE", comment: ""))
        }
        self.addButton(withTitle: NSLocalizedString("TELEPORT", comment: ""))
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

    /// Implementation to handle the response more nicely and add a second argument.
    func beginSheetModal(for sheetWindow: NSWindow,
                         completionHandler handler: CoordinateSelectionCompletionHandler? = nil) {

        super.beginSheetModal(for: sheetWindow) { [unowned self] response in
            // Get the user entered coordinates
            let coord = self.coordinateSelectionView?.getCoordinates()
            switch response {
            // User canceled
            case .alertFirstButtonReturn: handler?(.cancel, coord)
            // Navigate or teleport depending on whether navigate is available
            case .alertSecondButtonReturn: handler?( self.showsNavigationButton ? .navigate : .teleport, coord)
            // Teleport
            case .alertThirdButtonReturn: handler?( .teleport, coord)
            default: break
            }
        }
    }
}
