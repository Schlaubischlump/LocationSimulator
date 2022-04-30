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
let kMoveWhenStandingStill: String = "com.schlaubischlump.locationsimulator.movewhenstandingstill"
let kConfirmTeleportationKey: String = "com.schlaubischlump.locationsimulator.confirmteleportation"
let kMapTypeKey: String = "com.schlaubischlump.locationsimulator.maptype"
let kMovementControlBehaviourKey: String = "com.schlaubischlump.locationsimulator.movementcontrolbehaviour"

// Define the behaviour of the movement control when navigating using the arrow keys.
@objc enum MovementControlBehaviour: Int {
    case natural = 0
    case traditional = 1

    var localizedDescription: String {
        switch self {
        case .natural:     return "NATURAL_MOVEMENT_CONTROL_BEHAVIOUR_MSG_SETTING".localized
        case .traditional: return "TRADITIONAL_MOVEMENT_CONTROL_BEHAVIOUR_MSG_SETTING".localized
        }
    }
}

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var confirmTeleportation: Bool {
        get { return self.bool(forKey: kConfirmTeleportationKey) }
        set { self.setValue(newValue, forKey: kConfirmTeleportationKey) }
    }

    @objc dynamic var varyMovementSpeed: Bool {
        get { return self.bool(forKey: kVaryMovementSpeed) }
        set { self.setValue(newValue, forKey: kVaryMovementSpeed) }
    }

    @objc dynamic var moveWhenStandingStill: Bool {
        get { return self.bool(forKey: kMoveWhenStandingStill) }
        set { self.setValue(newValue, forKey: kMoveWhenStandingStill) }
    }

    @objc dynamic var movementControlBehaviour: MovementControlBehaviour {
        get {
            return MovementControlBehaviour(rawValue: self.integer(forKey: kMovementControlBehaviourKey)) ?? .natural
        }
        set { self.setValue(newValue.rawValue, forKey: kMovementControlBehaviourKey) }
    }

    /// Register the default NSUserDefault values.
    func registerGeneralDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kConfirmTeleportationKey: false,
            kMoveWhenStandingStill: false,
            kVaryMovementSpeed: false,
            kMovementControlBehaviourKey: MovementControlBehaviour.natural.rawValue
        ])
    }
}

class GeneralViewController: PreferenceViewControllerBase {
    @IBOutlet weak var confirmTeleportationCheckbox: NSButton!

    @IBOutlet weak var varyMovementSpeedCheckbox: NSButton!

    @IBOutlet weak var moveWhenStandingStillCheckbox: NSButton!

    @IBOutlet weak var movementControlBehaviourPopupButton: NSPopUpButton!

    @IBOutlet weak var movementControlBehaviourDescription: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.widthToFit()

        // load the current user settings
        self.confirmTeleportationCheckbox.state = UserDefaults.standard.confirmTeleportation    ? .on : .off
        self.varyMovementSpeedCheckbox.state = UserDefaults.standard.varyMovementSpeed          ? .on : .off
        self.moveWhenStandingStillCheckbox.state = UserDefaults.standard.moveWhenStandingStill  ? .on : .off

        let controlBehaviour = UserDefaults.standard.movementControlBehaviour
        self.movementControlBehaviourDescription.stringValue = controlBehaviour.localizedDescription
        self.movementControlBehaviourPopupButton.selectItem(at: controlBehaviour.rawValue)
    }

    /// Callback when the allow network devices toggle changes the state.
    @IBAction func confirmTeleportationChanged(_ sender: NSButton) {
        UserDefaults.standard.confirmTeleportation = (sender.state == .on)
    }

    @IBAction func varyMovementSpeedChanged(_ sender: NSButton) {
        UserDefaults.standard.varyMovementSpeed = (sender.state == .on)
    }

    @IBAction func moveWhenStandingStillChanged(_ sender: NSButton) {
        UserDefaults.standard.moveWhenStandingStill = (sender.state == .on)
    }

    @IBAction func movementControlBehaviourDidChange(_ sender: NSPopUpButton) {
        let controlBehaviour = MovementControlBehaviour(rawValue: sender.indexOfSelectedItem) ?? .natural
        UserDefaults.standard.movementControlBehaviour = controlBehaviour
        self.movementControlBehaviourDescription.stringValue = controlBehaviour.localizedDescription
    }
}
