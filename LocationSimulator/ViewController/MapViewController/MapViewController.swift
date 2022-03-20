//
//  MapViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// TODO: Fix UI blocks when the developer disk image is uploaded.

import Cocoa
import MapKit
import CoreLocation

class MapViewController: NSViewController {
    // MARK: - UI

    /// The main mapView.
    @IBOutlet weak var mapView: MapView!

    /// The main contentView which hosts all other views, including the mapView.
    var contentView: ContentView? {
        return self.view as? ContentView
    }

    // MARK: - Properties

    /// Current instance to spoof the iOS device location.
    var spoofer: LocationSpoofer?

    /// The current device managed by this viewController. Assigning this property will NOT automatically try to connect
    /// the device. You still need to call `connectDevice`. That beeing said, changing a device assigned to this
    /// viewController is not officially supported.
    public var device: Device? {
        get { return self.spoofer?.device }
        set {
            // Either we removed the device or the new device is not connected yet.
            self.deviceIsConnectd = false
            // Check that the device exists.
            guard let device = newValue else { return }
            // Create a spoofer instance for this device.
            self.spoofer = LocationSpoofer(device)
            self.spoofer?.delegate = self
        }
    }

    /// A reference to the current move type.
    var moveType: MoveType? {
        get { return self.spoofer?.moveType }
        set {
            guard let moveType = newValue else { return }
            self.spoofer?.moveType = moveType
        }
    }

    var speed: Double {
        get { return self.spoofer?.speed ?? 0 }
        set { self.spoofer?.speed = newValue }
    }

    var mapType: MKMapType {
        get { return self.mapView.mapType }
        set { self.mapView.mapType = newValue }
    }

    /// True to autofocus current location when the location changes, false otherwise.
    var autoFocusCurrentLocation = false {
        didSet {
            // Zoom to the current Location
            if self.autoFocusCurrentLocation == true, let currentLocation = self.spoofer?.currentLocation {
                self.mapView.zoomToLocation(currentLocation, animated: true)
            }
            // Send a notification
            NotificationCenter.default.post(name: .AutoFocusChanged, object: self, userInfo: [
                "autofocus": self.autoFocusCurrentLocation
            ])
        }
    }

    /// True if a alert is visible, false otherwise.
    var isShowingAlert: Bool = false

    /// True if the current device is connected, false otherwise.
    public private(set) var deviceIsConnectd: Bool = false {
        didSet {
            var userInfo: [String: Any] = [
                "status": self.deviceIsConnectd ? DeviceStatus.connected : DeviceStatus.disconnected
            ]
            // Add the device to the info if available.
            if let device = self.device {
                userInfo["device"] = device
            }
            // Post a notifcation about the new device status.
            NotificationCenter.default.post(name: .StatusChanged, object: self, userInfo: userInfo)
        }
    }

    // MARK: - Register Callbacks

    /// Register all actions for the controls in the lower left corner.
    private func registerControlsHUDActions() {
        // Add the movement button click action to move.
        self.contentView?.movementButtonHUD.clickAction = { [weak self] in
            guard let `self` = self else { return }
            self.view.window?.makeFirstResponder(self.mapView)

            switch self.spoofer?.moveState {
            case .manual: self.spoofer?.move()
            case .auto: self.spoofer?.moveState = .manual
            case .none: break
            }
        }
        // Add the movement button long press action to automove.
        self.contentView?.movementButtonHUD.longPressAction = { [weak self] in
            guard let `self` = self else { return }
            self.view.window?.makeFirstResponder(self.mapView)

            switch self.spoofer?.moveState {
            // Enable auto move
            case .manual:
                self.spoofer?.moveState = .auto
                self.spoofer?.move()
            // Disable auto move
            case .auto: self.spoofer?.moveState = .manual
            case .none: break
            }
        }
        // Add the callback when the heading changes
        self.contentView?.movementDirectionHUD.headingChangedAction = { [weak self] in
            guard let `self` = self else { return }
            // Update the location spoofer heading
            self.spoofer?.heading = self.mapView.camera.heading - self.getDirectionViewAngle()
        }
        // Add a reconnect action when clicking the error Indicator.
        self.contentView?.errorIndicationAction = { [weak self] in
            self?.connectDevice()
        }
    }

    /// Register callbacks for all mapView actions.
    private func registerMapViewActions() {
        let mapViewAction = { [weak self] (src: CLLocationCoordinate2D?, dst: CLLocationCoordinate2D) -> Void in
            if src == nil {
                // There is no current location => we can only teleport
                self?.spoofer?.setLocation(dst)
            } else {
                // There is a current location => ask the user to either teleport or navigate
                self?.requestTeleportOrNavigation(toCoordinate: dst)
            }
            self?.view.window?.makeFirstResponder(self?.mapView)
        }
        // Callback when the mapView is long pressed. Navigate or teleport to the new locatiom if possible.
        self.mapView.longPressAction = mapViewAction
        // Current location marker was dragged. Navigate or teleport to the new location.
        self.mapView.markerDragAction = mapViewAction
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Reset the contentView to its default values
        self.contentView?.reset()
        // register all actions for the mapView
        self.registerMapViewActions()
        // register all actions for the controls in the lower left corner
        self.registerControlsHUDActions()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Show the window controller.
        self.view.window?.makeFirstResponder(self.mapView)
        // change the autofocus state and thereby update the toolbar button as well
        self.autoFocusCurrentLocation = true
        // Try to load the current device if it is not yet connected.
        self.connectDevice()
    }

    override func mouseDown(with event: NSEvent) {
        self.view.window?.makeFirstResponder(self.mapView)
        super.mouseDown(with: event)
    }

    // MARK: - Helper

    /// Zoom into a given region.
    /// - Parameter region: The region to zoom into.
    public func zoomTo(region: MKCoordinateRegion) {
        self.mapView.setRegion(region, animated: true)
        // Make the mapview the first responder.
        self.view.window?.makeFirstResponder(self.mapView)
    }

    /// Reset the current location.
    public func resetLocation() {
        self.spoofer?.resetLocation()
    }

    /// Stop the current navigation.
    public func stopNavigation() {
        self.spoofer?.moveState = .manual
    }

    /// Move up or down.
    /// - Parameter flip: true to flip the diretion overlay by 180 degrees.
    public func move(flip: Bool) {
        guard self.spoofer?.moveState == .manual else { return }
        if flip {
            self.rotateDirectionViewBy(180)
        }
        self.spoofer?.move(appendToPendingTasks: false)
    }

    /// Toggle between the automove and the manual move state. If a navigation is running, it will be paused / resumed.
    public func toggleAutomoveState() {
        self.spoofer?.toggleAutomoveState()
    }

    /// The current angle of the movementDirectionHUD used to change the heading.
    /// - Return: the angle in degree
    public func getDirectionViewAngle() -> Double {
        return self.contentView?.movementDirectionHUD.currentHeadingInDegrees ?? 0.0
    }

    /// Rotate the movementDirectionHUD by a specific angle. The angle is added to the current heading.
    /// - Parameter angle: the angle in degree
    func rotateDirectionViewBy(_ angle: Double) {
        // update the headingView and the spoofer heading
        self.rotateDirectionViewTo(self.getDirectionViewAngle() + angle)
    }

    /// Set a new heading given by an angle.
    /// - Parameter angle: the angle in degree
    func rotateDirectionViewTo(_ angle: Double) {
        self.contentView?.rotateDirectionHUD(toAngleInDegrees: angle)
    }

    // MARK: - Load device

    /// Download the developer disk image and corresponding signature file for the specified version of the os.
    /// - Parameter os: the os type to download the image for
    /// - Parameter iOSVersion: the version number to download the image for
    /// - Return: true on success, false otherwise
    func downloadDeveloperDiskImage(os: String, iOSVersion: String) -> Bool {
        guard let window = self.view.window else { return false }
        // Show the alert and thereby start the download progress.
        let alert = ProgressAlert(os: os, version: iOSVersion)
        let response = alert.runSheetModal(forWindow: window)
        switch response {
        // Download was successfull
        case .OK : return true
        // No download link available.
        // show the error to the user
        case .failed: window.showError("DEVDISK_DOWNLOAD_FAILED_ERROR", message: "DEVDISK_DOWNLOAD_FAILED_ERROR_MSG")
        default: break
        }
        return false
    }

    /// Connect the current device. If no developer disk image is found, we try to download a matching one and reconnect
    /// the device.
    /// - Returns: true on success, false otherwise.
    @discardableResult
    func connectDevice() -> Bool {
        // Make sure we have a device to connect, which is not already connected. We need a window to show errors.
        guard !self.deviceIsConnectd, let device = self.device, let window = self.view.window else { return false }
        do {
            // Show the error indicator and a progress spinner.
            self.contentView?.showErrorInidcator()
            // If the pairing and uploading of the developer disk image is successfull create a spoofer instance.
            try device.pair()
            // Hide the error indicator if the device was connected sucessfully.
            self.contentView?.hideErrorInidcator()
            // We successfully connected the device.
            self.deviceIsConnectd = true
        } catch let error {
            // Stop the spinner even if an error occured.
            self.contentView?.stopSpinner()
            self.deviceIsConnectd = false
            // Handle the error message
            switch error {
            case DeviceError.devDiskImageNotFound(_, let os, let iOSVersion):
                // Try to download the developer disk image. Note this call is blocking.
                return self.downloadDeveloperDiskImage(os: os, iOSVersion: iOSVersion) ? self.connectDevice() : false
            case DeviceError.permisson:         window.showError("PERMISSION_ERROR", message: "PERMISSION_ERROR_MSG")
            case DeviceError.devDiskImageMount: window.showError("MOUNT_ERROR", message: "MOUNT_ERROR_MSG")
            case DeviceError.pair:              window.showError("PAIR_ERROR_MSG", message: "PAIR_ERROR_MSG")
            default:                            window.showError("UNKNOWN_ERROR", message: "UNKNOWN_ERROR_MSG")
            }
            return false
        }
        // Everything is working.
        return true
    }

    // MARK: - Teleport or Navigate

    /// Calculate the route from the current location to the specified coordinates and start the navigation.
    /// After the navigation to `toCoordinate` is finished, continue the navigation for the path specified in
    /// `additionalRoute`.
    /// - Parameter toCoordinate: tagret location.
    /// - Parameter additionalRoute: additional route to append to the calculated route
    private func navigate(toCoordinate coord: CLLocationCoordinate2D, additionalRoute: [CLLocationCoordinate2D] = []) {
        // calculate the route, display it and start moving
        guard let spoofer = self.spoofer, let currentLoc = self.spoofer?.currentLocation else { return }
        // the route is calculated differently based on the transport type
        let transportType: MKDirectionsTransportType = (spoofer.moveType == .car) ? .automobile : .walking
        // stop automoving before we calculate the route
        spoofer.moveState = .manual
        // indicate work while we calculate the route
        self.contentView?.startSpinner()
        // calulate the route to the destination
        currentLoc.calculateRouteTo(coord, transportType: transportType) { [weak self] route in
            // set the current route to follow
            spoofer.route = route + additionalRoute
            self?.contentView?.stopSpinner()
            // start automoving
            spoofer.moveState = .auto
            spoofer.move()
        }
    }

    /// Spoof the current location to the specified coordinates. If no coordinates are provided a user dialog is
    /// presented to enter the new coordinates. The user can then choose to navigate or teleport to the new location.
    /// - Parameter toCoordinate: new coordinates or nil
    func requestTeleportOrNavigation(toCoordinate coord: CLLocationCoordinate2D? = nil) {
        // make sure we can spoof a location and no dialog is currently showing
        guard !self.isShowingAlert, let window = self.view.window else { return }
        // Limit the amount of alerts of this kind to one.
        self.isShowingAlert = true
        // If a coordinate is provided to this function the user can not input one.
        // E.g. he did use use the recent location menu or dropped the current location to a new one.
        let showUserInput = (coord == nil)
        let showNavigation = self.spoofer?.currentLocation != nil
        // Ask the user what to do.
        let alert = CoordinateSelectionAlert(showNavigationButton: showNavigation, showUserInput: showUserInput)
        alert.beginSheetModal(for: window) { [weak self] response, userCoord in
            self?.isShowingAlert = false
            // Make sure the spoofer still exists and no unexpected error occured.
            guard let spoofer = self?.spoofer, let dstCoord = userCoord ?? coord else { return }
            switch response {
            // Cancel => set the location to the current one, in case the marker was dragged
            case .cancel:   self?.didChangeLocation(spoofer: spoofer, toCoordinate: spoofer.currentLocation)
            // Navigate to the target coordinates
            case .navigate: self?.navigate(toCoordinate: dstCoord)
            // Teleport to the new location and save the recent location
            case .teleport:
                spoofer.setLocation(dstCoord)
                self?.menubarController?.addLocation(dstCoord)
            default: break
            }
        }
    }

    /// Request routing for a GPX route. Teleport or navigate to the start of the route, then navigate along the route.
    /// - Parameter route: the coordinates for this GPX route
    func requestGPXRouting(route: [CLLocationCoordinate2D]) {
        // make sure we can spoof a location and no dialog is currently showing
        guard !self.isShowingAlert, let window = self.view.window else { return }
        // We need at least one coordinate
        guard !route.isEmpty else {
            self.view.window?.showError("EMPTY_ROUTE", message: "EMPTY_ROUTE_MSG")
            return
        }
        let showNavigation = self.spoofer?.currentLocation != nil
        let alert = CoordinateSelectionAlert(showNavigationButton: showNavigation, showUserInput: false)
        alert.beginSheetModal(for: window) {[weak self] response, _ in
            self?.isShowingAlert = false
            switch response {
            // Teleport to the start of the route and contiune the navigation from there on.
            case .teleport:
                guard let startCoord = route.first else { return }
                // Update the Recent location menu.
                self?.menubarController?.addLocation(startCoord)
                self?.spoofer?.currentLocation = startCoord
                // start navigating from the start of the route
                self?.spoofer?.moveState = .manual
                self?.spoofer?.route = route
                self?.spoofer?.moveState = .auto
                self?.spoofer?.move()
            // Navigate to the first coordinate and continue the navigation with the rest of the route.
            case .navigate:
                var route = route
                let startCoord = route.removeFirst()
                self?.navigate(toCoordinate: startCoord, additionalRoute: route)
            default: break
            }
        }
    }

    public func zoomIn() {
        self.mapView.zoomIn()
    }

    public func zoomOut() {
        self.mapView.zoomOut()
    }
}
