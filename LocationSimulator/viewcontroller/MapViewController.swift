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

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var moveButton: NSButton!

    @IBOutlet weak var moveButtonEffectView: BlurView!

    @IBOutlet weak var spinnerContainer: BlurView!

    @IBOutlet weak var spinner: NSProgressIndicator!

    @IBOutlet weak var moveHeadingControlsView: NSImageView!

    @IBOutlet weak var moveHeadingCircleView: NSImageView!
    
    @IBOutlet weak var moveHeadingEffectView: BlurView!

    @IBOutlet weak var separatorLine: NSBox!
    
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



    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

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

        if let layer = spinnerContainer.layer {
            layer.cornerRadius = 10.0
            layer.borderColor = CGColor(gray: 0.75, alpha: 1.0)
            layer.borderWidth = 1.0
        }

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

        // load the design for the current theme
        self.updateAppearance()

        // Fixme: This is ugly, but I can not get another solution to work...
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(themeChanged),
                                                          name: .AppleInterfaceThemeChanged, object: nil)
    }

    override func mouseDown(with event: NSEvent) {
        self.view.window?.makeFirstResponder(self.mapView)
        super.mouseDown(with: event)
    }

    override func viewDidAppear() {
        guard let window = self.view.window else { return }
        window.makeFirstResponder(self.mapView)
    }

    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }

    // MARK: - Dark mode

    func updateAppearance() {
        var isDarkMode = false
        if #available(OSX 10.14, *) {
            isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        self.spinnerContainer.tintColor = isDarkMode ? kDarkBlurColor : .white
        self.spinnerContainer.disableBlur = !isDarkMode
        self.moveButtonEffectView.disableBlur = !isDarkMode
        self.moveHeadingEffectView.disableBlur = !isDarkMode
        print(self.separatorLine.appearance, self.view.appearance)
    }

    @objc func themeChanged(_ notification: Notification) {
        self.updateAppearance()
    }

    // MARK: - Load device

    func loadDevice(_ udid: String) -> Bool {
        guard let window = self.view.window else { return false }

        do {
            let device: Device = try Device.load(udid)
            self.spoofer = LocationSpoofer(device)
            self.spoofer?.delegate = self
            return true
        } catch DeviceError.pair(let errorMsg) {
            window.showError(errorMsg, message: NSLocalizedString("PAIR_ERROR_MSG", comment: ""))
        } catch DeviceError.devDiskImageNotFound(_, let iOSVersion) {
            // try to download the DeveloperDiskImage files and try to connect to the device again
            let manager = FileManager.default
            if let devDMG = manager.getDeveloperDiskImage(iOSVersion: iOSVersion),
                let devSign = manager.getDeveloperDiskImageSignature(iOSVersion: iOSVersion)
            {
                let (diskLinks, signLinks): ([URL], [URL]) = manager.getDeveloperDiskImageDownloadLinks(iOSVersion: iOSVersion)

                // no download links for this iOS Version found
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
                let progressViewController = progressWindow.contentViewController as! ProgressViewController

                // set the delegate
                downloader.delegate = progressViewController
                let devDiskTask = DownloadTask(id: kDevDiskTaskID, source: diskLinks[0], destination: devDMG,
                                               description: NSLocalizedString("DEVDISK_DOWNLOAD_DESC", comment: ""))
                let devSignTask = DownloadTask(id: kDevSignTaskID, source: signLinks[0], destination: devSign,
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
                        // download finished successfully => try to load the device again
                        _ = self.loadDevice(udid)
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
        return false
    }


    // MARK: - Spinner control

    func startSpinner() {
        self.spinnerContainer.isHidden = false
        self.spinner.startAnimation(self)
    }

    func stopSpinner() {
        self.spinner.stopAnimation(self)
        self.spinnerContainer.isHidden = true
    }

    // MARK: - Rotate headerView helper function

    func getHeaderViewAngle() -> CGFloat {
        guard let layer = self.moveHeadingControlsView.layer else { return 0.0 }
        return atan2(layer.transform.m12, layer.transform.m11)
    }

    func rotateHeaderViewBy(_ angle: CGFloat) {
        // update the headingView and the spoofer heading
        self.rotateHeaderViewTo(self.getHeaderViewAngle() + angle)
    }

    func rotateHeaderViewTo(_ angle: CGFloat) {
        guard let layer = self.moveHeadingControlsView.layer else {return }

        // update the headingView and the spoofer heading
        self.moveHeadingControlsView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))
        layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        let heading: Double = (angle >= 0 ? 360 : 0) - 60 * Double(angle)
        self.spoofer?.heading = self.mapView.camera.heading + heading
    }

    // MARK: - Teleport

    func requestTeleportOrNavigation(toCoordinate coord: CLLocationCoordinate2D) {
        // if the current location is set ask the user if he wants to teleport or navigate to the destination
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("DESTINATION", comment: "")
        alert.informativeText = NSLocalizedString("TELEPORT_OR_NAVIGATE_MSG", comment: "")
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("NAVIGATE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("TELEPORT", comment: ""))
        alert.alertStyle = .informational
        alert.beginSheetModal(for: self.view.window!) { res in
            if res == NSApplication.ModalResponse.alertFirstButtonReturn {
                guard let spoofer = self.spoofer else { return }
                // cancel => set the location to the current one, in case the marker was dragged
                self.didChangeLocation(spoofer: spoofer, toCoordinate: spoofer.currentLocation)
            } else if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                // calculate the route, display it and start moving
                guard let spoofer = self.spoofer, let currentLoc = self.spoofer?.currentLocation else { return }

                let transportType: MKDirectionsTransportType = (spoofer.moveType == .car) ? .automobile : .walking

                // indicate work while we calculate the route
                self.startSpinner()

                // calulate the route to the destination
                currentLoc.calculateRouteTo(coord, transportType: transportType) {route in
                    // set the current route to follow
                    spoofer.route = route
                    self.stopSpinner()

                    // start automoving
                    if (spoofer.moveState != .auto) {
                        spoofer.moveState = .auto
                        spoofer.move()
                    }
                }
            } else if res == NSApplication.ModalResponse.alertThirdButtonReturn {
                // teleport to the new location
                self.spoofer?.setLocation(coord)
            }
        }
    }

    // MARK: - Interface Builder callbacks

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

    @objc func headingViewPressed(_ sender: NSClickGestureRecognizer) {
        self.view.window?.makeFirstResponder(self.mapView)

        guard sender.state == .changed || sender.state == .ended else { return }

        let loc = sender.location(in: self.moveHeadingControlsView)
        let dx = loc.x - self.moveHeadingControlsView.frame.width / 2
        let dy = loc.y - self.moveHeadingControlsView.frame.height / 2
        self.rotateHeaderViewTo(atan2(-dx, dy))
    }

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
