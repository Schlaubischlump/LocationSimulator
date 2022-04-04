//
//  GeneralTabWindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 29.10.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit

let kVaryMovementSpeed: String = "com.schlaubischlump.locationsimulator.varymovementspeed"
let kConfirmTeleportationKey: String = "com.schlaubischlump.locationsimulator.confirmteleportation"
let kMapTypeKey: String = "com.schlaubischlump.locationsimulator.maptype"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var mapType: MKMapType {
        get { return MKMapType(rawValue: UInt(self.integer(forKey: kMapTypeKey))) ?? .standard }
        set { self.setValue(newValue.rawValue, forKey: kMapTypeKey) }
    }

    @objc dynamic var varyMovementSpeed: Bool {
        get { return self.bool(forKey: kVaryMovementSpeed) }
        set { self.setValue(newValue, forKey: kVaryMovementSpeed) }
    }

    @objc dynamic var confirmTeleportation: Bool {
        get { return self.bool(forKey: kConfirmTeleportationKey) }
        set { self.setValue(newValue, forKey: kConfirmTeleportationKey) }
    }

    /// Register the default NSUserDefault values.
    func registerGeneralDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kConfirmTeleportationKey: false,
            kVaryMovementSpeed: false,
            kMapTypeKey: MKMapType.standard.rawValue
        ])
    }
}

class GeneralViewController: PreferenceViewControllerBase {
    @IBOutlet weak var confirmTeleportationCheckbox: NSButton!

    @IBOutlet weak var varyMovementSpeedCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.widthToFit()

        // load the current user settings
        self.varyMovementSpeedCheckbox.state = UserDefaults.standard.varyMovementSpeed ? .on : .off
        self.confirmTeleportationCheckbox.state = UserDefaults.standard.confirmTeleportation ? .on : .off
    }

    /// Callback when the allow network devices toggle changes the state.
    @IBAction func confirmTeleportationChanged(_ sender: NSButton) {
        UserDefaults.standard.confirmTeleportation = (sender.state == .on)
    }

    @IBAction func varyMovementSpeedChanged(_ sender: NSButton) {
        UserDefaults.standard.varyMovementSpeed = (sender.state == .on)
    }

}
