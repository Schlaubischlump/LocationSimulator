//
//  MapView.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import MapKit
import CoreLocation

// source location, destination location
typealias MapViewAction = (CLLocationCoordinate2D?, CLLocationCoordinate2D) -> Void

class MapView: MKMapView {

    /// Action to perform on a long press.
    public var longPressAction: MapViewAction?

    /// Action to perform when the current location marker is dragged
    public var markerDragAction: MapViewAction?

    /// True if the user is currently interacting with the map, false otherwise.
    public var isUserInteracting: Bool = false

    /// Current marker on the mapView.
    public private(set) var currentLocationMarker: MKPointAnnotation?

    /// Current navigation overlay that shows the path.
    private var navigationOverlay: MKOverlay?

    // MARK: - Constructor
    private func setup() {
        self.delegate = self
        self.showsZoomControls = true
        self.showsCompass = true
        self.showsScale = true
        // self.wantsLayer = true
        // self.showsUserLocation = true

        // Add long press gesture recognizer
        let mapPressGesture = NSPressGestureRecognizer(target: self, action: #selector(mapViewPressed(_:)))
        mapPressGesture.minimumPressDuration = 0.5
        mapPressGesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(mapPressGesture)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - Long press

    /// Callback when the map view is long pressed. Ask the user if he wants to teleport or navigate to the selected
    /// location.
    /// - Parameter sender: the long press gesture recognizer instance
    @objc private func mapViewPressed(_ sender: NSPressGestureRecognizer) {
        if sender.state == .ended {
            let loc = sender.location(in: self)
            let coordinate = self.convert(loc, toCoordinateFrom: self)
            // Call the assigned action
            self.longPressAction?(self.currentLocationMarker?.coordinate, coordinate)
        }
    }

    // MARK: - Zoom

    /// Zoom the mapView to a specific location.
    /// - Parameter coordinate: the coordinate to zoom to
    public func zoomToLocation(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        let currentRegion = self.region
        let span = MKCoordinateSpan(latitudeDelta: min(0.002, currentRegion.span.latitudeDelta),
                                    longitudeDelta: min(0.002, currentRegion.span.longitudeDelta))
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.setRegion(region, animated: animated)
    }

    // MARK: - Current location marker

    /// Place the current location marker at the specified position. Create a new marker if none exists.
    /// - Parameter atLocation: destination location of the marker
    /// - Return: true if the marker was created, false if it was moved.
    @discardableResult
    public func placeCurrentLocationMarker(atLocation coordinate: CLLocationCoordinate2D) -> Bool {
        var res: Bool = false
        // No marker does currenty exist => create and place the current location marker on the map
        if self.currentLocationMarker == nil {
            let marker = MKPointAnnotation()
            marker.title = "CURRENT_LOCATION".localized
            self.addAnnotation(marker)
            self.currentLocationMarker = marker
            // the marker was created
            res = true
        }

        // Updat the subtitles for the new location.
        self.currentLocationMarker?.subtitle = "\(coordinate.latitude), \(coordinate.longitude)"

         // Animate the marker to the new position.
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            context.allowsImplicitAnimation = true
            self.currentLocationMarker?.coordinate = coordinate
        }, completionHandler: nil)

        return res
    }

    /// Remove the current location marker from the map.
    /// - Return: true if the marker was removed, false otherwise.
    @discardableResult
    public func removeCurrentLocationMarker() -> Bool {
        if let marker = self.currentLocationMarker {
            self.removeAnnotation(marker)
            self.currentLocationMarker = nil
            return true
        }
        return false
    }

    // MARK: - Overlay

    /// Add the navigation overlay. If a current overlay is active this function will not add the overlay.
    /// Remove the navigation overlay before calling this function.
    /// Return: true on success, false otherwise
    @discardableResult
    public func addNavigationOverlay(withPath path: [CLLocationCoordinate2D]) -> Bool {
        // We only ever allow one navigation overlay.
        guard self.navigationOverlay == nil else {
            return false
        }

        self.navigationOverlay = MKPolyline(coordinates: path, count: path.count)
        self.addOverlay(self.navigationOverlay!, level: .aboveLabels)
        // FixMe: force a redraw to show the overlay... for some reason display is not working
        // this does block the UI for a little less then a second :/
        // self.mapView.setCenter(self.mapView.centerCoordinate, animated: true)
        return true
    }

    /// Remove the navigation overlay.
    /// Return: true on success, false otherwise
    @discardableResult
    public func removeNavigationOverlay() -> Bool {
        if let overlay = self.navigationOverlay {
            self.removeOverlay(overlay)
            self.navigationOverlay = nil
            return true
        }
        return false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // This is ugly...
        // We want to prevent the zoom in and zoom out default key bindings, so that our menu bar action gets performed
        // and lights up.
        let flags = event.modifierFlags
        let commandDown = flags.contains(.command) &&
                            !flags.contains(.option) &&
                            !flags.contains(.shift) &&
                            !flags.contains(.control)
        if (event.keyCode == 30 || event.keyCode == 44) && commandDown {
            return false
        }
        return super.performKeyEquivalent(with: event)
    }

    public func zoomIn() {
        // Perform the default NSResponder zoomIn.
        if !self.tryToPerform(Selector(("zoomIn:")), with: nil) {
            logError("\(String(describing: MenubarController.self)): Could not perform zoomIn")
        }
    }

    public func zoomOut() {
        // Perform the default NSResponder zoomOut
        if !self.tryToPerform(Selector(("zoomOut:")), with: nil) {
            logError("\(String(describing: MenubarController.self)): Could not perform zoomOut")
        }
    }
}
