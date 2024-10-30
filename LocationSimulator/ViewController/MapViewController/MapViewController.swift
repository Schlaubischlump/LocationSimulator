//
//  MapViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa
import MapKit
import CoreLocation
import LocationSpoofer

@objc(LSMapViewController) class MapViewController: NSViewController {
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
    /// the device. You still need to call `connectDevice`.
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
            // Apply the settings to the spoofer instance
            if UserDefaults.standard.varyMovementSpeed {
                self.spoofer?.movementSpeedVariance = kDefaultMovementSpeedVariance
            }
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

    var speed: CLLocationSpeed {
        get { return self.spoofer?.speed ?? 0 }
        set { self.spoofer?.speed = newValue }
    }

    var mapType: MKMapType {
        get { return self.mapView.mapType }
        set { self.mapView.mapType = newValue }
    }

    var isAutoMoving: Bool {
        return self.spoofer?.isAutoUpdating ?? false
    }

    @objc var isNavigating: Bool {
        switch self.spoofer?.moveState {
        case .navigation: return true
        default: return false
        }
    }

    /// Observe the vary movement speed setting
    var varyMovementSpeedSettingObserver: NSKeyValueObservation?
    /// Observe move when standing still observer
    var moveOnStandingStillSettingObserver: NSKeyValueObservation?

    /// True to autofocus current location when the location changes, false otherwise.
    @objc var autofocusCurrentLocation = false {
        didSet {
            // Zoom to the current Location
            if self.autofocusCurrentLocation == true, let currentLocation = self.spoofer?.currentLocation {
                self.mapView.zoomToLocation(currentLocation, animated: true)
            }
            // Send a notification
            NotificationCenter.default.post(name: .AutoFocusChanged, object: self, userInfo: [
                "autofocus": self.autofocusCurrentLocation
            ])
        }
    }

    /// True to autoreverse a route if the navigation destination is reached.
    @objc var autoreverseRoute = false {
        didSet {
            // Send a notification
            NotificationCenter.default.post(name: .AutoReverseChanged, object: self, userInfo: [
                "autoreverse": self.autoreverseRoute
            ])
        }
    }

    /// True if a alert is visible, false otherwise.
    @objc var isShowingAlert: Bool = false

    /// The current geocoding task for the window title if one exists
    var geocodingTask: GeocodingTask?

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
            guard let strongSelf = self else { return }
            strongSelf.view.window?.makeFirstResponder(strongSelf.mapView)

            switch strongSelf.spoofer?.moveState {
            case .manual:               try? strongSelf.spoofer?.move()
            case .auto, .navigation:    strongSelf.spoofer?.switchToInteractiveMoveState()
            case .none: break
            }
        }
        // Add the movement button long press action to automove.
        self.contentView?.movementButtonHUD.longPressAction = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.view.window?.makeFirstResponder(strongSelf.mapView)

            switch strongSelf.spoofer?.moveState {
            case .manual:               strongSelf.spoofer?.switchToAutoMoveState()
            case .auto, .navigation:    strongSelf.spoofer?.switchToInteractiveMoveState()
            case .none:                 break
            }
        }
        // Add the callback when the heading changes
        self.contentView?.movementDirectionHUD.headingChangedAction = { [weak self] in
            guard let strongSelf = self else { return }
            // Update the location spoofer heading
            strongSelf.spoofer?.heading = strongSelf.mapView.camera.heading - strongSelf.getDirectionViewAngle()
        }
        // Add a reconnect action when clicking the error Indicator.
        self.contentView?.errorIndicationAction = { [weak self] in
            self?.connectDevice()
        }
    }

    /// Register callbacks for all mapView actions.
    private func registerMapViewActions() {
        // swiftlint:disable unused_closure_parameter
        let mapViewAction = { [weak self] (src: CLLocationCoordinate2D?, dst: CLLocationCoordinate2D) -> Void in
            self?.requestTeleportOrNavigation(toCoordinate: dst)
            self?.view.window?.makeFirstResponder(self?.mapView)
        }
        // swiftlint:enable unused_closure_parameter

        // Callback when the mapView is long pressed. Navigate or teleport to the new locatiom if possible.
        self.mapView.longPressAction = mapViewAction
        // Current location marker was dragged. Navigate or teleport to the new location.
        self.mapView.markerDragAction = mapViewAction
    }

    /// Register all observers to respond to users setting changes.
    private func registerSettingsObservers() {
        // Listen for changes of the varyMovementSpeed settings
        self.varyMovementSpeedSettingObserver = UserDefaults.standard.observe(\.varyMovementSpeed,
                                                                      options: [.initial, .new]) { [weak self ](_, _) in
            let defaults = UserDefaults.standard
            self?.spoofer?.movementSpeedVariance = defaults.varyMovementSpeed ? kDefaultMovementSpeedVariance : nil
        }
        self.moveOnStandingStillSettingObserver = UserDefaults.standard.observe(\.moveWhenStandingStill,
                                                                      options: [.initial, .new]) { [weak self ](_, _) in
            if UserDefaults.standard.moveWhenStandingStill {
                self?.startMoveOnStandingStill()
            } else {
                self?.stopMoveOnStandingStill()
            }
        }

    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Reset the contentView to its default values
        self.contentView?.reset()
        // Register all actions for the mapView
        self.registerMapViewActions()
        // Register all actions for the controls in the lower left corner
        self.registerControlsHUDActions()
        // Listen for setting changes
        self.registerSettingsObservers()
        // Update the window title on macOS 11 and up.
        if #available(macOS 11.0, *) {
            self.geocodingTask = GeocodingTask { [weak self] name in
                self?.view.window?.title = name
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Show the window controller.
        self.view.window?.makeFirstResponder(self.mapView)
        // change the autofocus state and thereby update the toolbar button as well
        self.autofocusCurrentLocation = true
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
        self.spoofer?.switchToInteractiveMoveState()
    }

    /// Zoom into the map.
    public func zoomIn() {
        self.mapView.zoomIn()
    }

    /// Zoom out of the map.
    public func zoomOut() {
        self.mapView.zoomOut()
    }

    /// Move up or down.
    /// - Parameter flip: true to flip the diretion overlay by 180 degrees.
    public func move(flip: Bool) {
        if flip {
            self.rotateDirectionViewBy(180)
        }
        try? self.spoofer?.move()
    }

    /// Toggle between the automove and the manual move state. If a navigation is running, it will be paused / resumed.
    public func toggleAutoMove() {
        switch self.spoofer?.moveState {
        case .manual: self.spoofer?.switchToAutoMoveState()
        case .auto: self.spoofer?.switchToInteractiveMoveState()
        case .navigation: self.spoofer?.toggleAutoUpdate()
        default: break
        }
    }

    /// The current angle of the movementDirectionHUD used to change the heading.
    /// - Return: the angle in degree
    public func getDirectionViewAngle() -> Double {
        return self.contentView?.movementDirectionHUD.currentHeadingInDegrees ?? 0.0
    }

    /// Rotate the movementDirectionHUD by a specific angle. The angle is added to the current heading.
    /// - Parameter angle: the angle in degree
    public func rotateDirectionViewBy(_ angle: Double) {
        // update the headingView and the spoofer heading
        self.rotateDirectionViewTo(self.getDirectionViewAngle() + angle)
    }

    /// Set a new heading given by an angle.
    /// - Parameter angle: the angle in degree
    public func rotateDirectionViewTo(_ angle: Double, relativeToCamera: Bool = false) {
        if relativeToCamera {
            let cameraHeading = self.contentView?.cameraHeading ?? 0
            self.contentView?.rotateDirectionHUD(toAngleInDegrees: cameraHeading - angle)
        } else {
            self.contentView?.rotateDirectionHUD(toAngleInDegrees: angle)
        }
    }

    /// Start automovement when standing still.
    func startMoveOnStandingStill() {
        let moveOnStandingStill = UserDefaults.standard.moveWhenStandingStill
        if case .manual = self.spoofer?.moveState, moveOnStandingStill {
            self.spoofer?.startAutoUpdate()
        }
    }

    /// Stop automovement when standing still.
    func stopMoveOnStandingStill() {
        let moveOnStandingStill = UserDefaults.standard.moveWhenStandingStill
        if case .manual = self.spoofer?.moveState, !moveOnStandingStill {
            self.spoofer?.stopAutoUpdate()
        }
    }

    // MARK: - Load device

    /// Download the developer disk image and corresponding signature file for the specified version of the os.
    /// - Parameter os: the os type to download the image for
    /// - Parameter iOSVersion: the version number to download the image for
    /// - Return: true on success, false otherwise
    func downloadDeveloperDiskImage(os: String, iOSVersion: String) -> Bool {
        guard let window = self.view.window else { return false }
        // Show the alert and thereby start the download progress.
        let alert = DownloadProgressAlert(developerDiskImage: DeveloperDiskImage(os: os, version: iOSVersion))
        let response = alert.runSheetModal(forWindow: window)
        switch response {
        // Download was successfull
        case .OK: return true
        // No download link available
        case .failed: return false
        default: break
        }
        return false
    }

    @objc private func pairingSuccessfull() {
        /// The developer disk image has been upload successfully.
        self.mapView.userInteractionEnabled = true
        self.contentView?.stopSpinner()
        self.contentView?.hideErrorInidcator()
        self.deviceIsConnectd = true
    }

    @objc private func pairingFailed(error: Error) {
        guard !self.deviceIsConnectd, let device = device, let window = self.view.window else { return }

        self.contentView?.stopSpinner()
        self.deviceIsConnectd = false

        switch error {
        case DeviceError.devDiskImageNotFound(_):
            // Try to download the developer disk image and retry the upload.
            let os = device.productName!
            let version = device.majorMinorVersion!
            if self.downloadDeveloperDiskImage(os: os, iOSVersion: version) {
                self.connectDevice()
            } else {
                window.showError("DEVDISK_DOWNLOAD_FAILED_ERROR", message: "DEVDISK_DOWNLOAD_FAILED_ERROR_MSG")
            }
        case DeviceError.devMode:
            device.enabledDeveloperModeToggleInSettings()
            window.showError("DEVMODE_ERROR", message: "DEVMODE_ERROR_MSG")
        case DeviceError.permisson:
            window.showError("PERMISSION_ERROR", message: "PERMISSION_ERROR_MSG")
        case DeviceError.devDiskImageMount:
            window.showError("MOUNT_ERROR", message: "MOUNT_ERROR_MSG")
        case DeviceError.pair:
            window.showError("PAIR_ERROR_MSG", message: "PAIR_ERROR_MSG")
        default:
            window.showError("UNKNOWN_ERROR", message: "UNKNOWN_ERROR_MSG")
        }
    }

    @objc private func startPairing() {
        guard !self.deviceIsConnectd, let device = device else { return }

        do {
            try device.pair()

            self.performSelector(onMainThread: #selector(self.pairingSuccessfull), with: nil, waitUntilDone: false)
        } catch let error {
            self.performSelector(onMainThread: #selector(self.pairingFailed(error:)), with: error, waitUntilDone: false)
        }
    }

    /// Connect the current device. If no developer disk image is found, we try to download a matching one and reconnect
    /// the device.
    /// - Returns: true on success, false otherwise.
    func connectDevice() {
        // Make sure we have a device to connect, which is not already connected. We need a window to show errors.
        guard !self.deviceIsConnectd, device != nil else { return }

        self.mapView.userInteractionEnabled = false
        self.contentView?.startSpinner()
        self.contentView?.showErrorInidcator()

        // Run the pairing in a background thread
        // We do not use a DispatchQueue here on purpose ! Nesting two DispatchQueue.main.async calls will block, since
        // since the inner call will wait for the outer call to finish. When we present the Alert we already use a
        // DispatchQueue, thats why we use performSelector(inBackground:) here.
        self.performSelector(inBackground: #selector(self.startPairing), with: nil)
    }

    // MARK: - Teleport or Navigate

    /// Calculate the route from the current location to the specified coordinates and start the navigation.
    /// After the navigation to `toCoordinate` is finished, continue the navigation for the path specified in
    /// `additionalRoute`.
    /// - Parameter toCoordinate: tagret location.
    /// - Parameter additionalRoute: additional route to append to the calculated route
    private func navigate(toCoordinate coord: CLLocationCoordinate2D, additionalRoute: [CLLocationCoordinate2D] = []) {
        guard let spoofer = self.spoofer, let currentLoc = spoofer.currentLocation else { return }

        spoofer.stopAutoUpdate()
        self.contentView?.startSpinner()

        currentLoc.calculateRouteTo(coord, transportType: spoofer.moveType.transportType) { [weak self] route in
            var newRoute: [CLLocationCoordinate2D] = []
            // Always start at the current location
            if route.first != currentLoc {
                newRoute += [currentLoc]
            }
            newRoute += route
            // Always end at the destination, even if the route ends at the street
            if route.last != coord {
                newRoute += [coord]
            }
            // Add any additional route
            newRoute += additionalRoute

            self?.spoofer?.switchToNavigationState(newRoute)
            self?.contentView?.stopSpinner()
        }
    }

    func teleportToStartAndNavigate(route: [CLLocationCoordinate2D]) {
        guard let start = route.first else { return }
        self.menubarController?.addLocation(start)
        self.spoofer?.switchToNavigationState(route)
    }

    /// Spoof the current location to the specified coordinates. If no coordinates are provided a user dialog is
    /// presented to enter the new coordinates. The user can then choose to navigate or teleport to the new location.
    /// If no current location is set, this function will always teleport to the selected location.
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
            // Switch to interactive mode and teleport to the new location. Update the recent locations.
            case .teleport:
                spoofer.switchToInteractiveMoveState()
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
                // Update the recent location menu.
                self?.teleportToStartAndNavigate(route: route)
            // Navigate to the first coordinate and continue the navigation with the rest of the route.
            case .navigate:
                self?.navigate(toCoordinate: route.first!, additionalRoute: route)
            default: break
            }
        }
    }
}
