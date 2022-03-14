//
//  SidebarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class SidebarViewController: NSViewController {

    @IBOutlet var outlineView: NSOutlineView!

    /// Reference to the internal data source instance responsible for handling and displaying the device list.
    private var dataSource: SidebarDataSource?

    /// The observer when the cell selection changes.
    private var selectionObserver: NSObjectProtocol?

    // MARK: - Constructor

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for selection changes to change the current view controller. Segues are broken beyond repair on macOS.
        self.registerOutlineViewActions()

        // Create a new data source to handle the devices.
        self.dataSource = SidebarDataSource(sidebarView: self.outlineView)

        // Load the default value for network devices.
        IOSDevice.detectNetworkDevices = UserDefaults.standard.detectNetworkDevices

        // Tell the datas source to start listening for new devices.
        self.dataSource?.registerDeviceNotifications()
        IOSDevice.startGeneratingDeviceNotifications()
        SimulatorDevice.startGeneratingDeviceNotifications()
    }

    deinit {
        // Stop listening for new devices
        IOSDevice.stopGeneratingDeviceNotifications()
        SimulatorDevice.stopGeneratingDeviceNotifications()

        // Remove the selection observer.
        if let observer = self.selectionObserver {
            NotificationCenter.default.removeObserver(observer)
            self.selectionObserver = nil
        }
    }

    // MARK: - Selection changed

    private func registerOutlineViewActions() {
        self.selectionObserver = NotificationCenter.default.addObserver(
            forName: NSOutlineView.selectionDidChangeNotification, object: nil, queue: .main, using: { notification in
                // Only handle the relevant outline view.
                guard let siderbarView = notification.object as? NSOutlineView, siderbarView == self.outlineView else {
                    return
                }
                // We can only change the detail view if we find an enclosing splitView controller.
                guard let splitViewController = self.enclosingSplitViewController as? SplitViewController else {
                    return
                }

                // On macOS 11 use the line toolbar separator style for the MapViewController. Otherwise use None.
                var drawSeparator: Bool = false
                var viewController: Any?
                if let device = self.dataSource?.selectedDevice {
                    drawSeparator = true
                    // A device was connected => create and show the corresponding MapViewController.
                    viewController = self.storyboard?.instantiateController(withIdentifier: "MapViewController")
                    if let mapViewController = viewController as? MapViewController {
                        mapViewController.device = device
                        // Set the currently selected move type.
                        let windowController = self.view.window?.windowController as? WindowController
                        mapViewController.moveType = windowController?.moveType
                        mapViewController.mapType = UserDefaults.standard.mapType
                    }
                } else {
                    drawSeparator = false
                    // The last device was removed => create and show a NoDeviceViewController.
                    viewController = self.storyboard?.instantiateController(withIdentifier: "NoDeviceViewControlelr")
                    // If the sidebar is currently hidden, show it. The user might not know where to select a device.
                    if splitViewController.isSidebarCollapsed {
                        splitViewController.toggleSidebar()
                    }
                }

                // Get a reference to the splitViewController and assign the new detailViewController
                splitViewController.detailViewController = viewController as? NSViewController
                // Adjust the style of the detail item to show a separator line for the MapViewController.
                if #available(OSX 11.0, *) {
                    splitViewController.splitViewItems[1].titlebarSeparatorStyle = drawSeparator ? .line : .none
                }
        })
    }
}
