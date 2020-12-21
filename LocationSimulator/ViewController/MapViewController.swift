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
import Downloader

let kAnnotationViewCurrentLocationIdentifier = "AnnotationViewCurrentLocationIdentifier"

public extension NSNotification.Name {
    static let AutoFoucusCurrentLocationChanged = Notification.Name("AutoFoucusCurrentLocationChanged")
}

class MapViewController: NSViewController {
    // MARK: - UI
    /// The main mapView.
    @IBOutlet weak var mapView: MapView!
    /// The label which displays the total amount of meters you walked.
    @IBOutlet weak var totalDistanceLabel: NSTextField!
    /// Error indicator if something went wrong while connecting the device.
    @IBOutlet weak var errorIndicator: NSImageView!

    // MARK: - Properties

    /// Current instance to spoof the iOS device location.
    public var spoofer: LocationSpoofer?

    /// The main contentView which hosts all other views, including the mapView.
    public var contentView: ContentView? {
        return self.view as? ContentView
    }

    /// Window controller shown when the DeveloperDiskImage download is performed.
    private var progressWindowController: ProgressWindowController?

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
            self.spoofer?.heading = self.mapView.camera.heading - self.getHeaderViewAngle()
        }
    }

    /// Register callbacks for all mapView actions.
    private func registerMapViewActions() {
        // Callback when the mapView is long pressed. Navigate or teleport to the new locatiom if possible.
        self.mapView.longPressAction = { (src: CLLocationCoordinate2D?, dst: CLLocationCoordinate2D) -> Void in
            if src == nil {
                // There is no current location => we can only teleport
                self.spoofer?.setLocation(dst)
            } else {
                // There is a current location => ask the user to either teleport or navigate
                self.requestTeleportOrNavigation(toCoordinate: dst)
            }
            self.view.window?.makeFirstResponder(self.mapView)
        }

        // Current location marker was dragged. Navigate or teleport to the new location.
        self.mapView.markerDragAction = { (_: CLLocationCoordinate2D?, dst: CLLocationCoordinate2D) -> Void in
            self.requestTeleportOrNavigation(toCoordinate: dst)
        }
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // reset the total distance label
        self.totalDistanceLabel.stringValue = String(format: NSLocalizedString("TOTAL_DISTANCE", comment: ""), 0)

        // hide the controls
        self.contentView?.controlsHidden = true

        // register all actions for the mapView
        self.registerMapViewActions()

        // register all actions for the controls in the lower left corner
        self.registerControlsHUDActions()
    }

    override func viewDidAppear() {
        self.view.window?.makeFirstResponder(self.mapView)
        super.viewDidAppear()
    }

    override func mouseDown(with event: NSEvent) {
        self.view.window?.makeFirstResponder(self.mapView)
        super.mouseDown(with: event)
    }

    // MARK: - Load device
    func downloadDeveloperDiskImage(os: String, iOSVersion: String, _ completion: @escaping (Bool) -> Void = { _ in }) {
        guard let window = self.view.window else {
            completion(false)
            return
        }
        // Try to download the DeveloperDiskImage files and try to connect to the device again.
        let manager = FileManager.default
        if let devDMG = manager.getDeveloperDiskImage(os: os, iOSVersion: iOSVersion),
            let devSign = manager.getDeveloperDiskImageSignature(os: os, iOSVersion: iOSVersion) {

            let (diskLinks, signLinks) = manager.getDeveloperDiskImageDownloadLinks(os: os, version: iOSVersion)
            if diskLinks.isEmpty || signLinks.isEmpty {
                window.showError(NSLocalizedString("NO_DEVDISK_DOWNLOAD_ERROR", comment: ""),
                                 message: NSLocalizedString("NO_DEVDISK_DOWNLOAD_ERROR_MSG", comment: ""))
                completion(false)
                return
            }

            // create the downloader instance
            let downloader = Downloader()
            // create the progress popup sheet
            self.progressWindowController = ProgressWindowController.newInstance()
            let progressWindow = self.progressWindowController!.window!
            let progressViewController = progressWindow.contentViewController as? ProgressViewController

            // set the delegate
            downloader.delegate = progressViewController
            // We just use the first download link. In theory we could add multiple links for the same image.
            let devDiskTask = DownloadTask(dID: kDevDiskTaskID, source: diskLinks[0], destination: devDMG,
                                           description: NSLocalizedString("DEVDISK_DOWNLOAD_DESC", comment: ""))
            let devSignTask = DownloadTask(dID: kDevSignTaskID, source: signLinks[0], destination: devSign,
                                           description: NSLocalizedString("DEVSIGN_DOWNLOAD_DESC", comment: ""))

            // start the downlaod process
            downloader.start(devDiskTask)
            downloader.start(devSignTask)

            window.beginSheet(progressWindow) {[unowned self] response in
                self.progressWindowController = nil
                // cancel clicked => stop the download
                if response == .cancel {
                    downloader.cancel(devDiskTask)
                    downloader.cancel(devSignTask)
                    completion(false)
                } else if response == .OK {
                    completion(true)
                }
            }
        }
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

    // MARK: - Spinner control

    /// Show an animated progress spinner in the upper right corner.
    func startSpinner() {
        self.contentView?.startSpinner()
    }

    /// Hide and stop the progress spinner in the upper right corner.
    func stopSpinner() {
        self.contentView?.stopSpinner()
    }

    // MARK: - Direction HUD

    /// The current angle of the movementDirectionHUD used to change the heading.
    /// - Return: the angle in degree
    func getHeaderViewAngle() -> Double {
        return self.contentView?.movementDirectionHUD.currentHeadingInDegrees ?? 0.0
    }

    /// Rotate the movementDirectionHUD by a specific angle. The angle is added to the current heading.
    /// - Parameter angle: the angle in degree
    func rotateDirectionViewBy(_ angle: Double) {
        // update the headingView and the spoofer heading
        self.rotateDirectionViewTo(self.getHeaderViewAngle() + angle)
    }

    /// Set a new heading given by an angle.
    /// - Parameter angle: the angle in degree
    func rotateDirectionViewTo(_ angle: Double) {
        self.contentView?.rotateDirectionHUD(toAngleInDegrees: angle)
    }

    // MARK: - Teleport or Navigate

    /// Calculate the route from the current location to a target location and start the navigation.
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
        self.startSpinner()

        // calulate the route to the destination
        currentLoc.calculateRouteTo(coord, transportType: transportType) { route in
            // set the current route to follow
            spoofer.route = route + additionalRoute
            self.stopSpinner()

            // start automoving
            spoofer.moveState = .auto
            spoofer.move()
        }
    }

    /// Spoof the current location to the specified coordinates. If no coordinates are provided a user dialog is
    /// presented to enter the new coordinates. The user can then choose to navigate or teleport to the new location.
    /// - Parameter toCoordinate: new coordinates or nil
    func requestTeleportOrNavigation(toCoordinate coord: CLLocationCoordinate2D? = nil) {
        // make sure we can spoof a location and not dialog is currently showing
        guard !self.isShowingAlert else { return }

        // has the user provided coordinates to teleport to
        // e.g. he did use use the recent location menu or dropped the current location to a new one
        let userHasProvidedLocation = (coord != nil)

        // if the current location is set ask the user if he wants to teleport or navigate to the destination
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("DESTINATION", comment: "")
        alert.informativeText = NSLocalizedString("TELEPORT_OR_NAVIGATE_MSG", comment: "")
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        let navButton: NSButton = alert.addButton(withTitle: NSLocalizedString("NAVIGATE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("TELEPORT", comment: ""))
        alert.alertStyle = .informational

        // new coordinates to move to, either give by the function or read from a user input
        var newCoords: CLLocationCoordinate2D?

        // disable the navigate button if no current location exists
        if self.spoofer?.currentLocation == nil {
            navButton.isEnabled = false
        }

        // if no location is give request one from the user (e.g. Go to feature is used)
        if userHasProvidedLocation {
            newCoords = coord
        } else {
            let coordView = CoordinateSelectionView(frame: NSRect(x: 0, y: 0, width: 330, height: 40))
            // try to read coordinates from pasteboard and suggest them to the user
            if let (lat, long) = NSPasteboard.general.parseFirstItemAsCoordinates() {
                coordView.lat = lat
                coordView.long = long
            }
            alert.accessoryView = coordView
        }

        self.isShowingAlert = true

        alert.beginSheetModal(for: self.view.window!) { res in
            // Make ure the spoofer still exists
            guard let spoofer = self.spoofer else { return }

            // read coodinates from user input
            if !userHasProvidedLocation {
                if let coordSelectionView = alert.accessoryView as? CoordinateSelectionView {
                    newCoords = coordSelectionView.getCoordinates()
                } else {
                    // something went wrong...
                    self.isShowingAlert = false
                    return
                }
            }

            if res == NSApplication.ModalResponse.alertFirstButtonReturn {
                // cancel => set the location to the current one, in case the marker was dragged
                self.didChangeLocation(spoofer: spoofer, toCoordinate: spoofer.currentLocation)
            } else if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                // navigate to the target coordinates
                self.navigate(toCoordinate: newCoords!)
            } else if res == NSApplication.ModalResponse.alertThirdButtonReturn {
                // teleport to the new location
                spoofer.setLocation(newCoords!)
                // if we teleport we want to save this location as a recent location
                RecentLocationMenubarItem.addLocation(newCoords!)
            }

            self.isShowingAlert = false
        }
    }

    /// Request the routing for a GPX route. First teleport or navigate to the start of the route. Than navigate
    /// along the route.
    /// - Parameter route: the coordinates for this GPX route
    func requestGPXRouting(route: [CLLocationCoordinate2D]) {
        // make sure we can spoof a location and not dialog is currently showing
        guard !self.isShowingAlert else { return }

        // We need at least one coordinate
        guard route.count > 0 else {
            self.view.window?.showError(NSLocalizedString("EMPTY_ROUTE", comment: ""),
                                       message: NSLocalizedString("EMPTY_ROUTE_MSG", comment: ""))
            return
        }

        // if the current location is set ask the user if he wants to teleport or navigate to the destination
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("DESTINATION", comment: "")
        alert.informativeText = NSLocalizedString("TELEPORT_OR_NAVIGATE_GPX_MSG", comment: "")
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        let navButton: NSButton = alert.addButton(withTitle: NSLocalizedString("NAVIGATE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("TELEPORT", comment: ""))
        alert.alertStyle = .informational

        // disable the navigate button if no current location exists
        if self.spoofer?.currentLocation == nil {
            navButton.isEnabled = false
        }

        self.isShowingAlert = true

        /// Make a mutsating copy of the route.
        var route = route

        alert.beginSheetModal(for: self.view.window!) { res in
            // Make ure the spoofer still exists
            guard let spoofer = self.spoofer else { return }

            if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                // Navigate
                let coord = route.removeFirst()
                self.navigate(toCoordinate: coord, additionalRoute: route)
            } else if res ==  NSApplication.ModalResponse.alertThirdButtonReturn {
                // if we teleport we want to save this location as a recent location
                guard let startCoord = route.first else { return }

                RecentLocationMenubarItem.addLocation(startCoord)
                spoofer.currentLocation = startCoord

                // start navigating from the start of the route
                spoofer.moveState = .manual
                spoofer.route = route
                // start automoving
                spoofer.moveState = .auto
                spoofer.move()
            }

            self.isShowingAlert = false
        }
    }
}
