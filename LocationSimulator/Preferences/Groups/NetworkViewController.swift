//
//  NetworkTabViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 29.10.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import LocationSpoofer

let kAllowNetworkDevicesKey: String = "com.schlaubischlump.locationsimulator.allownetworkdevices"
let kPreferNetworkDevicesKey: String = "com.schlaubischlump.locationsimulator.prefernetworkdevices"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var preferNetworkDevices: Bool {
        get { return self.bool(forKey: kPreferNetworkDevicesKey) }
        set { self.setValue(newValue, forKey: kPreferNetworkDevicesKey) }
    }

    @objc dynamic var detectNetworkDevices: Bool {
        get { return self.bool(forKey: kAllowNetworkDevicesKey) }
        set { self.setValue(newValue, forKey: kAllowNetworkDevicesKey) }
    }

    /// Register the default NSUserDefault values.
    func registerNetworkDefaultValues() {
        UserDefaults.standard.register(defaults: [
            kAllowNetworkDevicesKey: true,
            kPreferNetworkDevicesKey: false
        ])
    }
}

class NetworkViewController: PreferenceViewControllerBase {
    @IBOutlet weak var allowNetworkDevicesCheckbox: NSButton!
    @IBOutlet weak var preferNetworkDevicesCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.widthToFit()

        // load the current user settings
        self.allowNetworkDevicesCheckbox.state = UserDefaults.standard.detectNetworkDevices ? .on : .off
        self.preferNetworkDevicesCheckbox.state = UserDefaults.standard.preferNetworkDevices  ? .on : .off
    }

    /// Callback when the allow network devices toggle changes the state.
    @IBAction func allowNetworkDevicesChanged(_ sender: NSButton) {
        let detectNetworkDevices = (sender.state == .on)

        // Update the UserDefaults
        UserDefaults.standard.detectNetworkDevices = detectNetworkDevices

        // Update the UI
        IOSDevice.detectNetworkDevices = detectNetworkDevices
        IOSDevice.stopGeneratingDeviceNotifications()
        IOSDevice.startGeneratingDeviceNotifications()
    }

    /// Callback when the prefer network devices toggle changes the state.
    @IBAction func preferNetworkDevicesChanged(_ sender: NSButton) {
        let preferNetworkDevices = (sender.state == .on)

        UserDefaults.standard.preferNetworkDevices = preferNetworkDevices

        IOSDevice.preferNetworkConnectionDefault = preferNetworkDevices
        IOSDevice.stopGeneratingDeviceNotifications()
        IOSDevice.startGeneratingDeviceNotifications()
    }
}
