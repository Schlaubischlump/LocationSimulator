//
//  GeneralTabWindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 29.10.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit

let kConfirmTeleportationKey: String = "com.schlaubischlump.locationsimulator.confirmteleportation"
let kMapTypeKey: String = "com.schlaubischlump.locationsimulator.maptype"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var mapType: MKMapType {
        get { return MKMapType(rawValue: UInt(self.integer(forKey: kMapTypeKey))) ?? .standard }
        set { self.setValue(newValue.rawValue, forKey: kMapTypeKey) }
    }

    @objc dynamic var confirmTeleportation: Bool {
        get { return self.bool(forKey: kConfirmTeleportationKey) }
        set { self.setValue(newValue, forKey: kConfirmTeleportationKey) }
    }

    /// Register the default NSUserDefault values.
    func registerGeneralDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kConfirmTeleportationKey: false,
            kMapTypeKey: MKMapType.standard.rawValue
        ])
    }
}

class GeneralViewController: NSViewController {
    @IBOutlet weak var confirmTeleportationCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // load the current user settings
        self.confirmTeleportationCheckbox.state = UserDefaults.standard.confirmTeleportation ? .on : .off
    }

    /// Callback when the allow network devices toggle changes the state.
    @IBAction func confirmTeleportationChanged(_ sender: NSButton) {
        UserDefaults.standard.confirmTeleportation = (sender.state == .on)
    }
}
