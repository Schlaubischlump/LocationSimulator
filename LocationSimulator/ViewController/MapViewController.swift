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

public extension NSNotification.Name {
    static let AutoFoucusCurrentLocationChanged = Notification.Name("AutoFoucusCurrentLocationChanged")
}

class MapViewController: NSViewController {
    // MARK: - UI

    /// The main mapView.
    @IBOutlet weak var mapView: MapView!

    /// The main contentView which hosts all other views, including the mapView.
    public var contentView: ContentView? {
        return self.view as? ContentView
    }

    // MARK: - Properties

    /// Current instance to spoof the iOS device location.
    public var spoofer: LocationSpoofer?

    /// True to autofocus current location when the location changes, False otherwise.
    var autoFocusCurrentLocation = false {
        didSet {
            // Zoom to the current Location
            if self.autoFocusCurrentLocation == true, let currentLocation = self.spoofer?.currentLocation {
                self.mapView.zoomToLocation(currentLocation, animated: true)
            }

            // Send a notification
            NotificationCenter.default.post(name: .AutoFoucusCurrentLocationChanged, object: autoFocusCurrentLocation)
        }
    }

    /// True if a alert is visible, false otherwise.
    var isShowingAlert: Bool = false

    /// True if currently a device is connected.
    var deviceIsConnectd: Bool {
        return self.spoofer?.device != nil
    }

    // MARK: - Actions

    /// Register all actions for the controls in the lower left corner.
    private func registerControlsHUDActions() {
        // Add the movement button click action to move.
        self.contentView?.movementButtonHUD.clickAction = {
            self.view.window?.makeFirstResponder(self.mapView)

            switch self.spoofer?.moveState {
            case .manual: self.spoofer?.move()
            case .auto: self.spoofer?.moveState = .manual
            case .none: break
            }
        }

        // Add the movement button long press action to automove.
        self.contentView?.movementButtonHUD.longPressAction = {
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
        self.contentView?.movementDirectionHUD.headingChangedAction = {
            // Update the location spoofer heading
            self.spoofer?.heading = self.mapView.camera.heading - self.getDirectionViewAngle()
        }
    }

    /// Register callbacks for all mapView actions.
    private func registerMapViewActions() {
        let mapViewAction: MapViewAction = { (src: CLLocationCoordinate2D?, dst: CLLocationCoordinate2D) -> Void in
            if src == nil {
                // There is no current location => we can only teleport
                self.spoofer?.setLocation(dst)
            } else {
                // There is a current location => ask the user to either teleport or navigate
                self.requestTeleportOrNavigation(toCoordinate: dst)
            }
            self.view.window?.makeFirstResponder(self.mapView)
        }

        // Callback when the mapView is long pressed. Navigate or teleport to the new locatiom if possible.
        self.mapView.longPressAction = mapViewAction

        // Current location marker was dragged. Navigate or teleport to the new location.
        self.mapView.markerDragAction = mapViewAction
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // reset the total distance label
        self.contentView?.setTotalDistance(meter: 0)

        // hide the controls
        self.contentView?.controlsHidden = true

        // register all actions for the mapView
        self.registerMapViewActions()

        // register all actions for the controls in the lower left corner
        self.registerControlsHUDActions()
    }

    override func viewDidAppear() {
        self.view.window?.makeFirstResponder(self.mapView)

        // change the autofocus state and thereby update the toolbar button as well
        self.autoFocusCurrentLocation = true

        super.viewDidAppear()
    }

    override func mouseDown(with event: NSEvent) {
        self.view.window?.makeFirstResponder(self.mapView)
        super.mouseDown(with: event)
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
        case .failed: window.showError(NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR", comment: ""),
                                       message: NSLocalizedString("DEVDISK_DOWNLOAD_FAILED_ERROR_MSG", comment: ""))
        default: break
        }
        return false
    }

    /// Load a new device given by its udid. A new spoofer instance is created based on the device. All location change
    /// or reset actions are directed to this spoofer instance. If you change the device you have to call this method to
    /// change the current spoofer instance to interact with it. You can not interact with more than one device at a
    ///  time.
    /// - Parameter udid: device unique identifier
    /// - Return: true on success, false otherwise
    /// - Throws:
    ///    * `DeviceError.devDiskImageNotFound`: No DeveloperDiskImage.dmg or Signature file found in App Support folder
    ///    * `DeviceError.devDiskImageMount`: Error mounting the DeveloperDiskImage.dmg file
    ///    * `DeviceError.permisson`: Permission error while accessing the App Support folder
    ///    * `DeviceError.productInfo`: Could not read the devices product version string
    func load(device: Device) throws {
        guard let window = self.view.window else { return }

        do {
            try device.pair()
            // If the pairing and uploading of the developer disk image is successfull create a spoofer instance.
            self.spoofer = LocationSpoofer(device)
            self.spoofer?.delegate = self
        } catch let error {
            // device connection failed => no device is currently connected
            // If you remove this line the following bug will occure:
            // 1. sucessfully connect a device (=> spoofer instance is set)
            // 2. change to a new device where the connection fails (=> spoofer instance is still set)
            // 3. select the original device (=> spoofer.devive is still the same as the selected device)
            // => Nothing happend and you can not use the selected device
            self.spoofer = nil

            switch error {
            case DeviceError.pair(let errorMsg):
                window.showError(errorMsg, message: NSLocalizedString("PAIR_ERROR_MSG", comment: ""))
            case DeviceError.devDiskImageNotFound(_, _, _):
                break
            case DeviceError.permisson(let errorMsg):
                window.showError(errorMsg, message: NSLocalizedString("PERMISSION_ERROR_MSG", comment: ""))
            case DeviceError.devDiskImageMount(let errorMsg, _, _):
                window.showError(errorMsg, message: NSLocalizedString("MOUNT_ERROR_MSG", comment: ""))
            default:
                window.showError(NSLocalizedString("UNKNOWN_ERROR", comment: ""),
                                 message: NSLocalizedString("UNKNOWN_ERROR_MSG", comment: ""))
            }
            throw error
        }
    }

    // MARK: - Direction HUD

    /// The current angle of the movementDirectionHUD used to change the heading.
    /// - Return: the angle in degree
    func getDirectionViewAngle() -> Double {
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
        currentLoc.calculateRouteTo(coord, transportType: transportType) { route in
            // set the current route to follow
            spoofer.route = route + additionalRoute
            self.contentView?.stopSpinner()

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

        let alert = CoordinateSelectionAlert(showNavigationButton: showNavigation, showUserInput: showUserInput)
        alert.beginSheetModal(for: window) { response, userCoord in
            self.isShowingAlert = false

            // Make sure the spoofer still exists and no unexpected error occured.
            guard let spoofer = self.spoofer, let dstCoord = userCoord ?? coord else { return }

            switch response {
            // Cancel => set the location to the current one, in case the marker was dragged
            case .cancel: self.didChangeLocation(spoofer: spoofer, toCoordinate: spoofer.currentLocation)
            // Navigate to the target coordinates
            case .navigate: self.navigate(toCoordinate: dstCoord)
            // Teleport to the new location and save the recent location
            case .teleport:
                spoofer.setLocation(dstCoord)
                RecentLocationMenubarItem.addLocation(dstCoord)
            default: break
            }
        }
    }

    /// Request the routing for a GPX route. First teleport or navigate to the start of the route. Than navigate
    /// along the route.
    /// - Parameter route: the coordinates for this GPX route
    func requestGPXRouting(route: [CLLocationCoordinate2D]) {
        // make sure we can spoof a location and no dialog is currently showing
        guard !self.isShowingAlert, let window = self.view.window else { return }

        // We need at least one coordinate
        guard !route.isEmpty else {
            self.view.window?.showError(NSLocalizedString("EMPTY_ROUTE", comment: ""),
                                       message: NSLocalizedString("EMPTY_ROUTE_MSG", comment: ""))
            return
        }

        let showNavigation = self.spoofer?.currentLocation != nil
        let alert = CoordinateSelectionAlert(showNavigationButton: showNavigation, showUserInput: false)

        alert.beginSheetModal(for: window) { response, _ in
            self.isShowingAlert = false

            // Make sure the spoofer still exists
            guard let spoofer = self.spoofer else { return }

            switch response {
            /// Teleport to the start of the route and contiune the navigation from there on.
            case .teleport:
                guard let startCoord = route.first else { return }

                RecentLocationMenubarItem.addLocation(startCoord)
                spoofer.currentLocation = startCoord

                // start navigating from the start of the route
                spoofer.moveState = .manual
                spoofer.route = route
                // start automoving
                spoofer.moveState = .auto
                spoofer.move()
            /// Navigate to the first coordinate and continue the navigation with the rest of the route.
            case .navigate:
                var route = route
                let startCoord = route.removeFirst()
                self.navigate(toCoordinate: startCoord, additionalRoute: route)

            default: break
            }
        }
    }
}
