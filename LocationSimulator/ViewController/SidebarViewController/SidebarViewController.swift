//
//  SidebarController.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import LocationSpoofer
import SuggestionPopup

let kMinimumSidebarWidth = 150.0

let kEnableSidebarSearchField = {
    if #available(OSX 11.0, *) {
        return true
    } else {
        return false
    }
}()

class SidebarViewController: NSViewController {

    @IBOutlet var outlineView: NSOutlineView!

    /// Reference to the internal data source instance responsible for handling and displaying the device list.
    private var dataSource: SidebarDataSource?

    /// The observer when the cell selection changes.
    private var selectionObserver: NSObjectProtocol?

    /// The enclosing scrollView containing the outlineView.
    private var scrollView: NSScrollView? {
        self.outlineView.enclosingScrollView
    }

    /// The location search completer used on macOS 11 and greater.
    private var searchCompleter: LocationSearchCompleter?

    private var windowController: WindowController? {
        self.view.window?.windowController as? WindowController
    }

    // MARK: - Constructor

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for selection changes to change the current view controller. Segues are broken beyond repair on macOS.
        self.registerOutlineViewActions()

        // Create a new data source to handle the devices.
        self.dataSource = SidebarDataSource(sidebarView: self.outlineView)
        self.outlineView.postsBoundsChangedNotifications = true

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification, object: nil
        )

        // Load the default value for network devices.
        IOSDevice.detectNetworkDevices = UserDefaults.standard.detectNetworkDevices

        // Tell the datas source to start listening for new devices.
        self.dataSource?.registerDeviceNotifications()
        IOSDevice.startGeneratingDeviceNotifications()
        SimulatorDevice.startGeneratingDeviceNotifications()

        // Add a searchbar to the sidebar in macOS 11 and up
        if kEnableSidebarSearchField {
            self.setupSearchField()
        }
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

    override func viewWillAppear() {
        super.viewWillAppear()
        // Relayout the findbar with the correct titlebar height.
        self.scrollView?.findBarView?.layout()
    }

    // MARK: - macOS 11.0 SearchField

    var searchEnabled: Bool = false {
        didSet {
            let searchbarView = self.scrollView?.findBarView as? SearchbarView
            searchbarView?.userInteractionEnabled = self.searchEnabled
        }
    }

    private func setupSearchField() {
        let searchbarView = SearchbarView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        searchbarView.userInteractionEnabled = false
        self.scrollView?.findBarView = searchbarView
        self.scrollView?.isFindBarVisible = true

        // We use closures instead of linkin the function, because the windowController is still nil on viewDidLoad
        let searchCompleter = LocationSearchCompleter(searchField: searchbarView.searchField)
        searchCompleter.minimumWindowWidth = kMinimumSidebarWidth + 15
        searchCompleter.onSelect = { [weak self] text, suggestion in
            self?.windowController?.searchBarOnSelect(text: text, suggestion: suggestion)
        }
        searchCompleter.onBecomeFirstReponder = { [weak self] in
            self?.windowController?.searchBarOnBecomeFirstReponder()
        }
        searchCompleter.onResignFirstReponder = { [weak self] in
            self?.windowController?.searchBarOnBecomeFirstReponder()
        }
        self.searchCompleter = searchCompleter
    }

    func clearSearchField() {
        let searchbarView = self.scrollView?.findBarView as? SearchbarView
        searchbarView?.searchField.stringValue = ""
    }

    func apply(sidebarStyle: SidebarStyle) {
        let backgroundEffectView = self.view.superview as? NSVisualEffectView
        backgroundEffectView?.blendingMode = sidebarStyle.blendingMode
        backgroundEffectView?.material = sidebarStyle.material

        let searchbarView = self.scrollView?.findBarView as? SearchbarView
        let headerEffectView = searchbarView?.effectView
        headerEffectView?.blendingMode = sidebarStyle.blendingMode
        headerEffectView?.material = sidebarStyle.material
    }

    // MARK: - Callback
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        guard (notification.object as? NSView)?.enclosingScrollView == self.scrollView,
              let scrollView = self.scrollView, let searchbarView = scrollView.findBarView as? SearchbarView else {
            return
        }
        let offsetY = searchbarView.frame.maxY
        let contentOffsetY = -scrollView.documentVisibleRect.minY - offsetY
        searchbarView.showSeparatorShadow = contentOffsetY < 0
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
                        mapViewController.speed = windowController?.speed ?? 0
                        mapViewController.mapType = UserDefaults.standard.mapType
                    }
                } else {
                    drawSeparator = false
                    // The last device was removed => create and show a NoDeviceViewController.
                    viewController = self.storyboard?.instantiateController(withIdentifier: "NoDeviceViewController")
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
