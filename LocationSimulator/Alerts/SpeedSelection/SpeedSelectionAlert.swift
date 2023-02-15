//
//  CoordinateSelectionAlert.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import CoreLocation

typealias SpeedSelectionCompletionHandler = ((NSApplication.ModalResponse, Double) -> Void)

/// Alert view which lets the user update the speed value.
class SpeedSelectionAlert: NSAlert {

    public var speedSelectionView = SpeedSelectionView(frame: CGRect(x: 0, y: 0, width: 170, height: 40))

    init(defaultValue: CLLocationSpeed) {
        super.init()

        self.messageText = "CHANGE_SPEED".localized
        self.addButton(withTitle: "CANCEL".localized)
        self.addButton(withTitle: "OK".localized)
        self.alertStyle = .informational

        var frame = self.speedSelectionView.frame
        frame.size.width = 200
        let contentView = NSView(frame: frame)

        let offX = (frame.width - self.speedSelectionView.frame.width) / 2
        self.speedSelectionView.frame.origin.x = offX
        self.speedSelectionView.speed = defaultValue.inKmH

        contentView.addSubview(self.speedSelectionView)
        self.accessoryView = contentView
    }

    override func beginSheetModal(for sheetWindow: NSWindow,
                                  completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        fatalError("Do not use this function. Use the two argument implementation instead.")
    }

    /// Implementation to handle the response more nicely and add a second argument.
    func beginSheetModal(for sheetWindow: NSWindow,
                         completionHandler handler: SpeedSelectionCompletionHandler? = nil) {
        // Show the actual coordinate selection.
        super.beginSheetModal(for: sheetWindow) { [unowned self] response in
            // Get the user entered coordinates
            let speed = self.speedSelectionView.getSpeed()
            switch response {
            // User canceled
            case .alertFirstButtonReturn: handler?(.cancel, speed)
            // Navigate or teleport depending on whether navigate is available
            case .alertSecondButtonReturn: handler?(.OK, speed)
            default: break
            }
        }
    }
}
