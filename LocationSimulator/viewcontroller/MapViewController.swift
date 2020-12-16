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

let kDarkBlurColor = NSColor(calibratedWhite: 0.4, alpha: 0.5)

public extension NSNotification.Name {
    static let AutoFoucusCurrentLocationChanged = Notification.Name("AutoFoucusCurrentLocationChanged")
    static let AppleInterfaceThemeChanged = Notification.Name("AppleInterfaceThemeChangedNotification")
}

class MapViewController: NSViewController {
    // MARK: - UI
    /// The main mapView.
    @IBOutlet weak var mapView: MKMapView!
    /// The button in the lower left corner used to move around the map when clicked.
    @IBOutlet weak var moveButton: NSButton!
    /// The blur effect view used to get a nicer dark mode interface for the `moveButton`.
    @IBOutlet weak var moveButtonEffectView: BlurView!
    /// A container view which hosts the progress spinner.
    @IBOutlet weak var spinnerContainer: BlurView!
    /// The main progress spinner in the upper right corner to indicate the user, that we are performing an operation.
    @IBOutlet weak var spinner: NSProgressIndicator!
    /// The view used to change the current heading inside the map.
    @IBOutlet weak var moveHeadingControlsView: NSImageView!
    /// Outer circle view used to make the `moveHeadingControlsView` a little bit nicer.
    @IBOutlet weak var moveHeadingCircleView: NSImageView!
    /// The blur effect view used to get a nicer dark mode interface for the `moveHeadingControlsView`.
    @IBOutlet weak var moveHeadingEffectView: BlurView!
    /// A simple separator line at the bottom of the view to separate the bottom bar from the map view.
    @IBOutlet weak var separatorLine: NSBox!
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

    /// Show or hide the navigation controls in the lower left corner.
    var controlsHidden: Bool = true {
        didSet {
            // hide / show the navigation controls
            self.moveHeadingCircleView.isHidden = self.controlsHidden
            self.moveHeadingControlsView.isHidden = self.controlsHidden
            self.moveButton.isHidden = self.controlsHidden
            self.moveButtonEffectView.isHidden = self.controlsHidden
            self.moveHeadingEffectView.isHidden = self.controlsHidden
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

        // add a drop shadow to the circle view
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.5)
        shadow.shadowBlurRadius = 0.5
        shadow.shadowOffset = NSSize(width: 0.0, height: -0.5)
        self.moveHeadingCircleView.shadow = shadow

        // configure the blur view for dark mode
        self.moveHeadingEffectView.tintColor = kDarkBlurColor
        self.moveHeadingEffectView.maskImage = #imageLiteral(resourceName: "CircleOutline")

        self.moveButtonEffectView.tintColor = kDarkBlurColor
        self.moveButtonEffectView.maskImage = #imageLiteral(resourceName: "MoveButton")

        // customize spinner
        self.spinnerContainer.isHidden = true
        self.spinnerContainer.wantsLayer = true

        self.spinnerContainer.layer?.cornerRadius = 10.0
        self.spinnerContainer.layer?.borderColor = CGColor(gray: 0.75, alpha: 1.0)
        self.spinnerContainer.layer?.borderWidth = 1.0

        // Add gesture recognizer
        let mapPressGesture = NSPressGestureRecognizer(target: self, action: #selector(mapViewPressed(_:)))
        mapPressGesture.minimumPressDuration = 0.5
        mapPressGesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(mapPressGesture)

        let headingPressGesture = NSPressGestureRecognizer(target: self, action: #selector(headingViewPressed(_:)))
        headingPressGesture.minimumPressDuration = 0.1
        headingPressGesture.numberOfTouchesRequired = 1
        self.moveHeadingControlsView.addGestureRecognizer(headingPressGesture)

        let moveClickGesture = NSClickGestureRecognizer(target: self, action: #selector(moveClicked(_:)))
        moveClickGesture.numberOfTouchesRequired = 1
        moveButton.addGestureRecognizer(moveClickGesture)

        let moveLongPressGesture = NSPressGestureRecognizer(target: self, action: #selector(moveLongPressed(_:)))
        moveLongPressGesture.minimumPressDuration = 1.0
        moveLongPressGesture.numberOfTouchesRequired = 1
        moveButton.addGestureRecognizer(moveLongPressGesture)

        // hide the controls
        self.controlsHidden = true

        // are we currently showing a alert
        self.isShowingAlert = false

        // load the design for the current theme
        self.updateAppearance()

        // Fixme: This is ugly, but I can not get another solution to work...
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged),
                                               name: .AppleInterfaceThemeChanged, object: nil)
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

    // MARK: - Dark mode

    /// Update the view appearance to light or dark mode based on the UserDefaults `AppleInterfaceStyle` key.
    func updateAppearance() {
        var isDarkMode = false
        if #available(OSX 10.14, *) {
            isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        self.spinnerContainer.tintColor = isDarkMode ? kDarkBlurColor : .white
        self.spinnerContainer.disableBlur = !isDarkMode
        self.moveButtonEffectView.disableBlur = !isDarkMode
        self.moveHeadingEffectView.disableBlur = !isDarkMode
        self.separatorLine.borderColor = isDarkMode ? .black : NSColor(calibratedRed: 167.0/255.0, green: 167.0/255.0,
                                                                       blue: 167.0/255.0, alpha: 1.0)
    }

    /// Callback when the theme changed from light to dark or dark to light.
    @objc func themeChanged(_ notification: Notification) {
        self.updateAppearance()
    }

    // MARK: - Load device

    /// Load a new device given by its udid. A new spoofer instance is created based on the device. All location change
    /// or reset actions are directed to this spoofer instance. If you change the device you have to call this method to
    /// change the current spoofer instance to interact with it. You can not interact with more than one device at a
    ///  time.
    /// - Parameter udid: device unique identifier
    /// - Return: true on success, false otherwise
    func load(device: Device) -> Bool {
        guard let window = self.view.window else { return false }

        var ret = false

        do {
            try device.pair()
            // If the pairing and uploading of the developer disk image is successfull create a spoofer instance.
            self.spoofer = LocationSpoofer(device)
            self.spoofer?.delegate = self
            return true
        } catch DeviceError.pair(let errorMsg) {
            window.showError(errorMsg, message: NSLocalizedString("PAIR_ERROR_MSG", comment: ""))
        } catch DeviceError.devDiskImageNotFound(_, let iOSVersion) {
            // Try to download the DeveloperDiskImage files and try to connect to the device again.
            let manager = FileManager.default
            if let devDMG = manager.getDeveloperDiskImage(iOSVersion: iOSVersion),
                let devSign = manager.getDeveloperDiskImageSignature(iOSVersion: iOSVersion) {
                // could not find the developer disk images
                // fetch the download url from the plist if available
                let (diskLinks, signLinks): ([URL], [URL]) = manager.getDeveloperDiskImageDownloadLinks(iOSVersion: iOSVersion)

                // no download links for this iOS Version found => try to use the fallback URL
                if diskLinks.isEmpty || signLinks.isEmpty {
                    window.showError(NSLocalizedString("NO_DEVDISK_DOWNLOAD_ERROR", comment: ""),
                                     message: NSLocalizedString("NO_DEVDISK_DOWNLOAD_ERROR_MSG", comment: ""))
                    return false
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
                    } else if response == .OK {
                        // download finished successfully => try to load the device again if it is still connected
                        let connectedDevices = (window.windowController as? WindowController)?.devices ?? []
                        if connectedDevices.contains(device) {
                            ret = self.load(device: device)
                        }
                    }
                }
            }
        } catch DeviceError.permisson(let errorMsg) {
            window.showError(errorMsg, message: NSLocalizedString("PERMISSION_ERROR_MSG", comment: ""))
        } catch DeviceError.devDiskImageMount(let errorMsg, _) {
            window.showError(errorMsg, message: NSLocalizedString("MOUNT_ERROR_MSG", comment: ""))
        } catch {
            window.showError(NSLocalizedString("UNKNOWN_ERROR", comment: ""),
                             message: NSLocalizedString("UNKNOWN_ERROR_MSG", comment: ""))
        }

        // device connection failed => no device is currently connected
        // If you remove this line the following bug will occure:
        // 1. sucessfully connect a device (=> spoofer instance is set)
        // 2. change to a new device where the connection fails (=> spoofer instance is still set)
        // 3. select the original device (=> spoofer.devive is still the same as the selected device)
        // => Nothing happend and you can not use the selected device
        self.spoofer = nil

        return ret
    }

    // MARK: - Spinner control

    /// Show an animated progress spinner in the upper right corner.
    func startSpinner() {
        self.spinnerContainer.isHidden = false
        self.spinner.startAnimation(self)
    }

    /// Hide and stop the progress spinner in the upper right corner.
    func stopSpinner() {
        self.spinner.stopAnimation(self)
        self.spinnerContainer.isHidden = true
    }

    // MARK: - Rotate headerView helper function

    /// The current angle of the headingView used to change the heading.
    /// - Return: the angle in degree
    func getHeaderViewAngle() -> CGFloat {
        guard let layer = self.moveHeadingControlsView.layer else { return 0.0 }
        return atan2(layer.transform.m12, layer.transform.m11)
    }

    /// Rotate the headingView and update the location spoofer heading state by a specific angle. The angle is applied
    /// to the current heading.
    /// - Parameter angle: the angle in degree
    func rotateHeaderViewBy(_ angle: CGFloat) {
        // update the headingView and the spoofer heading
        self.rotateHeaderViewTo(self.getHeaderViewAngle() + angle)
    }

    /// Set a new heading based on a specified angle.
    /// - Parameter angle: the angle in degree
    func rotateHeaderViewTo(_ angle: CGFloat) {
        guard let layer = self.moveHeadingControlsView.layer else {return }

        // update the headingView and the spoofer heading
        self.moveHeadingControlsView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))
        layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        let heading: Double = (angle >= 0 ? 360 : 0) - 60 * Double(angle)
        self.spoofer?.heading = self.mapView.camera.heading + heading
    }

    // MARK: - Teleport

    /// Spoof the current location to the specified coordinates. If no coordinates are provided a user dialog is
    /// presented to enter the new coordinates. The user can then choose to navigate or teleport to the new location.
    /// - Parameter toCoordinate: new coordinates or nil
    func requestTeleportOrNavigation(toCoordinate coord: CLLocationCoordinate2D? = nil) {
        // make sure we can spoof a location
        guard let spoofer = self.spoofer else { return }
        // do not allow multiple dialogs
        guard !self.isShowingAlert else { return }

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

        // if no location is give request one from the user
        if coord == nil {
            let coordView = CoordinateSelectionView(frame: NSRect(x: 0, y: 0, width: 330, height: 40))

            // try to read coordinates from pasteboard and suggest them to the user
            if let pasteboardItem = NSPasteboard.general.pasteboardItems?.first?.string(forType: .string) {
                let components = pasteboardItem.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                if components.count == 2 {
                    let first = String(components.first!).trimmingCharacters(in: .whitespaces)
                    let second = String(components.last!).trimmingCharacters(in: .whitespaces)
                    if let lat = Double(first), let long = Double(second) {
                        coordView.lat = lat
                        coordView.long = long
                    }
                }
            }

            alert.accessoryView = coordView
        } else {
            newCoords = coord
        }

        self.isShowingAlert = true

        alert.beginSheetModal(for: self.view.window!) { res in
            // read coodinates from user input
            if coord == nil {
                if let coordSelectionView = alert.accessoryView as? CoordinateSelectionView {
                    newCoords = coordSelectionView.getCoordinates()
                } else {
                    // something went wrong...
                    self.isShowingAlert = false
                    return
                }
            }

            if res == NSApplication.ModalResponse.alertFirstButtonReturn {
                guard let spoofer = self.spoofer else { return }
                // cancel => set the location to the current one, in case the marker was dragged
                self.didChangeLocation(spoofer: spoofer, toCoordinate: spoofer.currentLocation)
            } else if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                // calculate the route, display it and start moving
                guard let spoofer = self.spoofer, let currentLoc = self.spoofer?.currentLocation else { return }

                let transportType: MKDirectionsTransportType = (spoofer.moveType == .car) ? .automobile : .walking

                // stop automoving before we calculate the route
                spoofer.moveState = .manual

                // indicate work while we calculate the route
                self.startSpinner()

                // calulate the route to the destination
                currentLoc.calculateRouteTo(newCoords!, transportType: transportType) {route in
                    // set the current route to follow
                    spoofer.route = route
                    self.stopSpinner()

                    // start automoving
                    spoofer.moveState = .auto
                    spoofer.move()
                }
            } else if res == NSApplication.ModalResponse.alertThirdButtonReturn {
                // teleport to the new location
                spoofer.setLocation(newCoords!)
                // if we teleport we want to save this location as a recent location
                RecentLocationMenubarItem.addLocation(newCoords!)
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

    /// Change the heading when the user clicks inside heading view.
    /// - Parameter sender: the click gesture recognizer instance
    @objc func headingViewPressed(_ sender: NSClickGestureRecognizer) {
        self.view.window?.makeFirstResponder(self.mapView)

        guard sender.state == .changed || sender.state == .ended else { return }

        let loc = sender.location(in: self.moveHeadingControlsView)
        let deltaX = loc.x - self.moveHeadingControlsView.frame.width / 2
        let deltaY = loc.y - self.moveHeadingControlsView.frame.height / 2
        self.rotateHeaderViewTo(atan2(-deltaX, deltaY))
    }

    /// Move north if the inner circle of the heading view is clicked.
    /// - Parameter sender: the click gesture recognizer instance
    @objc func moveClicked(_ sender: NSClickGestureRecognizer) {
        self.view.window?.makeFirstResponder(self.mapView)

        guard let mState = self.spoofer?.moveState, sender.state == .ended else { return }

        switch mState {
        case .manual:
            self.spoofer?.move()
        case .auto:
            // Disable auto move
            self.spoofer?.moveState = .manual
        }
    }

    /// Start automoving if the inner circle of the heading view is long pressed.
    /// - Parameter sender: the long press gesture recognizer instance
    @objc func moveLongPressed(_ sender: NSPressGestureRecognizer) {
        self.view.window?.makeFirstResponder(self.mapView)

        guard let mState = self.spoofer?.moveState, sender.state == .began else { return }

        switch mState {
        case .manual:
            // Enable auto move
            self.spoofer?.moveState = .auto
            self.spoofer?.move()
        case .auto:
            // Disable auto move
            self.spoofer?.moveState = .manual
        }
    }
}
