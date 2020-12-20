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

let kAnnotationViewCurrentLocationIdentifier = "AnnotationViewCurrentLocationIdentifier"

public extension NSNotification.Name {
    static let AutoFoucusCurrentLocationChanged = Notification.Name("AutoFoucusCurrentLocationChanged")
}

class MapViewController: NSViewController {
    // MARK: - UI
    /// The main mapView.
    @IBOutlet weak var mapView: MKMapView!
    /// The label which displays the total amount of meters you walked.
    @IBOutlet weak var totalDistanceLabel: NSTextField!
    /// Error indicator if something went wrong while connecting the device.
    @IBOutlet weak var errorIndicator: NSImageView!

    // MARK: - Properties

    /// Current instance to spoof the iOS device location.
    public var spoofer: LocationSpoofer?

    /// Current marker on the mapView.
    public var currentLocationMarker: MKPointAnnotation?

    /// Current route overlay shown when navigation is active.
    public var routeOverlay: MKOverlay?

    /// The main contentView which hosts all other views, including the mapView.
    public var contentView: ContentView? {
        return self.view as? ContentView
    }

    /// Window controller shown when the DeveloperDiskImage download is performed.
    private var progressWindowController: ProgressWindowController?

    /// True to autofocus current location when the location changes, False otherwise.
    var autoFocusCurrentLocation = false {
        didSet {
            if self.autoFocusCurrentLocation == true,
                let currentLocation = self.spoofer?.currentLocation {
                // Zoom to the current Location
                let currentRegion = mapView.region
                let span = MKCoordinateSpan(latitudeDelta: min(0.002, currentRegion.span.latitudeDelta),
                                            longitudeDelta: min(0.002, currentRegion.span.longitudeDelta))
                let region = MKCoordinateRegion(center: currentLocation, span: span)
                mapView.setRegion(region, animated: true)
            }

            // Send a notification
            NotificationCenter.default.post(name: .AutoFoucusCurrentLocationChanged,
                                            object: autoFocusCurrentLocation)
        }
    }

    /// True if a alert is visible, false otherwise.
    var isShowingAlert: Bool = false

    /// True if currently a device is connected.
    var deviceIsConnectd: Bool {
        return self.spoofer?.device != nil
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // reset the total distance label
        self.totalDistanceLabel.stringValue = String(format: NSLocalizedString("TOTAL_DISTANCE", comment: ""), 0)

        // configure the map view
        self.mapView.delegate = self
        self.mapView.wantsLayer = true // otherwise the BlurView won't work
        self.mapView.showsZoomControls = false
        self.mapView.showsScale = true
        //self.mapView.showsUserLocation = true

        // Add gesture recognizer
        let mapPressGesture = NSPressGestureRecognizer(target: self, action: #selector(mapViewPressed(_:)))
        mapPressGesture.minimumPressDuration = 0.5
        mapPressGesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(mapPressGesture)

        // hide the controls
        self.contentView?.controlsHidden = true

        // are we currently showing a alert
        self.isShowingAlert = false

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
            case .manual:
                // Enable auto move
                self.spoofer?.moveState = .auto
                self.spoofer?.move()
            case .auto:
                // Disable auto move
                self.spoofer?.moveState = .manual
            case .none:
                break
            }
        }
    }

    /// Make the window the first responder if it receives a mouse click.
    /// - Parameter event: the mouse event
    override func mouseDown(with event: NSEvent) {
        self.view.window?.makeFirstResponder(self.mapView)
        super.mouseDown(with: event)
    }

    override func viewDidAppear() {
        guard let window = self.view.window else { return }
        window.makeFirstResponder(self.mapView)
    }

    // MARK: - Load device
    func downloadDeveloperDiskImage(iOSVersion: String, _ completion: @escaping (Bool) -> Void = { _ in }) {
        guard let window = self.view.window else {
            completion(false)
            return
        }
        // Try to download the DeveloperDiskImage files and try to connect to the device again.
        let manager = FileManager.default
        if let devDMG = manager.getDeveloperDiskImage(iOSVersion: iOSVersion),
            let devSign = manager.getDeveloperDiskImageSignature(iOSVersion: iOSVersion) {

            let (diskLinks, signLinks): ([URL], [URL]) = manager.getDeveloperDiskImageDownloadLinks(iOSVersion:
                                                                                                        iOSVersion)
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
    ///    * `DeviceError.productVersion`: Could not read the devices product version string
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
            case DeviceError.devDiskImageNotFound(_, _):
                break
            case DeviceError.permisson(let errorMsg):
                window.showError(errorMsg, message: NSLocalizedString("PERMISSION_ERROR_MSG", comment: ""))
            case DeviceError.devDiskImageMount(let errorMsg, _):
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

    // MARK: - Rotate headerView helper function

    /// The current angle of the headingView used to change the heading.
    /// - Return: the angle in degree
    func getHeaderViewAngle() -> Double {
        return self.contentView?.movementControlHUD.currentHeadingInDegrees ?? 0.0
    }

    /// Rotate the headingView and update the location spoofer heading state by a specific angle. The angle is applied
    /// to the current heading.
    /// - Parameter angle: the angle in degree
    func rotateHeaderViewBy(_ angle: Double) {
        // update the headingView and the spoofer heading
        self.rotateHeaderViewTo(self.getHeaderViewAngle() + angle)
    }

    /// Set a new heading based on a specified angle.
    /// - Parameter angle: the angle in degree
    func rotateHeaderViewTo(_ angle: Double) {
        self.contentView?.rotateOverlayTo(angleInDegrees: angle)
        self.spoofer?.heading = self.mapView.camera.heading - self.getHeaderViewAngle()
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

    // MARK: - Interface Builder callbacks

    /// Callback when the map view is long pressed. Ask the user if he wants to teleport or navigate to the selected
    /// location.
    /// - Parameter sender: the long press gesture recognizer instance
    @objc func mapViewPressed(_ sender: NSPressGestureRecognizer) {
        if sender.state == .ended {
            let loc = sender.location(in: mapView)
            let coordinate = mapView.convert(loc, toCoordinateFrom: mapView)

            if self.currentLocationMarker == nil {
                self.spoofer?.setLocation(coordinate)
            } else {
                self.requestTeleportOrNavigation(toCoordinate: coordinate)
            }
            self.view.window?.makeFirstResponder(self.mapView)
        }
    }
}
