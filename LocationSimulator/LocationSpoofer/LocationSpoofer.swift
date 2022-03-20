//
//  LocationSpoofer.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Constants

let kAutoMoveDuration: Double = 0.05

typealias SucessHandler = (_ sucessfull: Bool) -> Void

// MARK: - Enums

enum MoveState {
    case manual
    case auto
}

enum MoveType: Int, CaseIterable {
    case walk = 0
    case cycle
    case car

    /// Speed in meters per second
    var speed: Double {
        switch self {
        case .walk:
            return 1.39 // 5km/h
        case .cycle:
            return 4.167  // 15km/h
        case .car:
            return 11.112 // 40km/h
        }
    }
}

// MARK: - Spoofer

class LocationSpoofer {

    // MARK: - Properties

    /// Current simulated location.
    public var currentLocation: CLLocationCoordinate2D?

    /// Change the direction in which to move (you can change this while automoving is active).
    public var heading: Double = 0.0

    /// If this property is set, automove will follow along the route and not responds to direction changes.
    /// This list will be consumed while the path updates.
    public var route: [CLLocationCoordinate2D]

    /// Delegate which is informed about location changes.
    public weak var delegate: LocationSpooferDelegate?

    /// The current automove state. Use `manual` to navigate by clicking the move button. Use `auto` to walk into the
    /// direction specified by the control view in the lower left corner of the map. If additionally a route is
    /// specified, the automove feature will automatically follow along this path.
    public var moveState: MoveState = .manual {
        willSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.willChangeMoveState(spoofer: strongSelf, moveState: strongSelf.moveState)
            }
        }
        didSet {
            // cancel the automove timer if we change to manual moving
            if self.moveState == .manual {
                self.autoMoveTimer?.invalidate()
                self.autoMoveTimer = nil
                // reset the route if we change to manual moving
                self.route = []
            }

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.didChangeMoveState(spoofer: strongSelf, moveState: strongSelf.moveState)
            }
        }
    }

    /// The current move type which defines the speed. The available types are: walk, cycle and drive.
    public var moveType: MoveType = .walk {
        willSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.willChangeMoveType(spoofer: strongSelf, moveType: strongSelf.moveType)
            }
        }
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.didChangeMoveType(spoofer: strongSelf, moveType: strongSelf.moveType)
            }
        }
    }

    /// The connected iOS Device.
    public let device: Device

    /// Total moved distance in m
    public var totalDistance: Double = 0.0

    /// Internal background queue which performs the location update operations
    private let dispatchQueue: DispatchQueue

    /// Internal timer required for automoving.
    private var autoMoveTimer: Timer?

    /// True if a location update task is already running, false otehrwise.
    private var hasPendingTask: Bool = false

    /// True if the navigation is currently paused
    public var navigationIsPaused: Bool {
        if self.moveState == .manual || self.route.count == 0 {
            return false
        }
        return self.autoMoveTimer == nil
    }

    /// Change the current speed
    public var speed: Double = 0

    // MARK: - Constructor

    init(_ device: Device) {
        self.route = []
        self.device = device
        self.currentLocation = nil
        self.dispatchQueue = DispatchQueue(label: "locationUpdates", qos: .userInteractive)
    }

    // MARK: - Location Spoofing (Public)

    /// Async call to change the device location. Use the delegate method to get informed when the location did change.
    /// - Parameter coordinate: new location
    public func setLocation(_ coordinate: CLLocationCoordinate2D) {
        // stop automoving if required
        self.moveState = .manual
        // set the new location
        self.setLocation(coordinate) { _ in }
    }

    /// Disable location spoofing for the connected iDevice. This will reset the location to the real device location.
    public func resetLocation() {
        self.hasPendingTask = true
        // inform delegate that the location will be reset
        self.delegate?.willChangeLocation(spoofer: self, toCoordinate: nil)
        // disable automoving
        self.moveState = .manual

        dispatchQueue.async { [weak self] in
            // try to reset the location
            let success: Bool = self?.device.disableSimulation() ?? false
            if success {
                self?.totalDistance = 0.0
                self?.currentLocation = nil
            }

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                if success {
                    strongSelf.delegate?.didChangeLocation(spoofer: strongSelf, toCoordinate: nil)
                } else {
                    strongSelf.delegate?.errorChangingLocation(spoofer: strongSelf, toCoordinate: nil)
                }
                self?.hasPendingTask = false
            }
        }
    }

    /// Pause a navigation if it is running. Otherwise toggle between automove and manual move.
    public func toggleAutomoveState() {
        switch self.moveState {
        // switch to automove
        case .manual:
            self.moveState = .auto
            self.move()
        case .auto:
            if self.route.isEmpty {
                // stop automove if no navigation is active
                self.moveState = .manual
            } else {
                // pause / resume the navigation
                self.pauseResumeNavigation()
            }
        }
    }

    /// Public wrapper around the private move function.
    @objc public func move(appendToPendingTasks append: Bool = true) {
        self.move(timer: nil, appendToPendingTasks: append)
    }

    // MARK: - Location Spoofing (Private)

    /// Change the location on the connected iDevice to the new coordinates.
    /// - Parameter coordinate: new location
    /// - Parameter delay: delay after which the operation should be executed
    /// - Parameter completion: completion block after the update oparation was performed
    private func setLocation(_ coordinate: CLLocationCoordinate2D, completion:@escaping SucessHandler) {
        self.hasPendingTask = true
        // inform delegate that the location will change
        self.delegate?.willChangeLocation(spoofer: self, toCoordinate: coordinate)

        dispatchQueue.async { [weak self] in
            // try to simulate the location on the device
            let success: Bool = self?.device.simulateLocation(coordinate) ?? false
            if success {
                self?.totalDistance += self?.currentLocation?.distanceTo(coordinate: coordinate) ?? 0
                self?.currentLocation = coordinate
            }

            // call the completion block and inform the delegate about the change
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                completion(success)
                if success {
                    strongSelf.delegate?.didChangeLocation(spoofer: strongSelf, toCoordinate: coordinate)
                } else {
                    strongSelf.delegate?.errorChangingLocation(spoofer: strongSelf, toCoordinate: coordinate)
                }
                strongSelf.hasPendingTask = false
            }
        }
    }

    // MARK: - Move / Automove

    /// Calculate the next location. The next location depends on the current route if one is defined.
    /// Otherwise the next location is based on the current heading.
    /// - Parameter distance: distance to move
    /// - Return: new location
    private func calculateNextLocation(_ distance: Double = 0.0) -> CLLocationCoordinate2D? {
        guard let currentLocation = self.currentLocation else {
            return nil
        }

        // move on the specified route
        if self.route.count > 0 {
            let coord = self.route.first!

            let heading = currentLocation.heading(toLocation: coord)
            var nextLocation = self.calculateNextLocation(distance, heading: heading)
            // snap into place if we are close enough to a marker
            if nextLocation.distanceTo(coordinate: coord) <= distance {
                nextLocation = coord
                // remove the coordinate from the path
                self.route = Array(self.route.dropFirst())

                // stop moving if we reached the end of the path
                if self.route.count == 0 {
                    self.moveState = .manual
                }
            }

            return nextLocation
        }

        return self.calculateNextLocation(distance, heading: self.heading)
    }

    /// Calculate the new location based on the current heading and distance.
    /// - Parameter distance: distance to move
    /// - Parameter heading: direction to move in
    /// - Return: new location
    private func calculateNextLocation(_ distance: Double = 0.0, heading: Double = 0.0) -> CLLocationCoordinate2D {
        // move into the direction of heading
        let latitude = currentLocation!.latitude
        let longitude = currentLocation!.longitude

        let earthCircle = 2 * .pi * 6371000.0

        let latDistance = distance * cos(heading * .pi / 180)
        let latPerMeter = 360 / earthCircle
        let latDelta = latDistance * latPerMeter
        let newLat = latitude + latDelta

        let lngDistance = distance * sin(heading * .pi / 180)
        let earthRadiusAtLng = 6371000.0 * cos(newLat * .pi / 180)
        let earthCircleAtLng = 2 * .pi * earthRadiusAtLng
        let lngPerMeter = 360 / earthCircleAtLng
        let lngDelta = lngDistance * lngPerMeter
        let newLng = longitude + lngDelta

        return CLLocationCoordinate2D(latitude: newLat, longitude: newLng)
    }

    /// Pause or resume the current navigation.
    private func pauseResumeNavigation() {
        if self.moveState == .manual || self.route.count == 0 { return }

        if self.autoMoveTimer != nil {
            self.delegate?.willPauseNavigation(spoofer: self)
            self.autoMoveTimer?.invalidate()
            self.autoMoveTimer = nil
            self.delegate?.didPauseNavigation(spoofer: self)
        } else {
            self.delegate?.willResumeNavigation(spoofer: self)
            self.move()
            self.delegate?.didResumeNavigation(spoofer: self)
        }
    }

    /// Move `moveType.distance` meters per second `into the direction defined by `heading` or by the current route.
    /// If automove is activated this function will reschedule itself.
    /// - Parameter timer: The timer instance which schedule the function
    /// - Parameter appendToPendingTasks: True to append the location operation to the DispatchQueue, false otherwise
    @objc private func move(timer: Timer?, appendToPendingTasks: Bool = true) {
        // we don't want to append a new task
        if !appendToPendingTasks && self.hasPendingTask { return }

        // if the `setLocation` takes to long we might need to move a little bit more to keep the speed.
        var distance: Double = 0
        if let userInfo = timer?.userInfo as? [String: UInt64], let lastTime = userInfo["time"] {
            let durationInSeconds = Double(DispatchTime.now().uptimeNanoseconds - lastTime) / 1000000000
            distance = self.speed * durationInSeconds
        } else {
            distance = self.speed * kAutoMoveDuration
        }

        // calculate the next location based on the distance we want to move
        guard let nextLocation = self.calculateNextLocation(distance) else {
            return
        }

        // save the time when we start sending the location information
        let time = DispatchTime.now().uptimeNanoseconds

        // send the new location information
        self.setLocation(nextLocation) { [weak self] successfull in
            // cancel automove if the location could no be changed
            guard successfull, let strongSelf = self else { return }

            // reschedule ourself
            if strongSelf.moveState == .auto {
                strongSelf.autoMoveTimer = Timer.scheduledTimer(timeInterval: TimeInterval(kAutoMoveDuration),
                                                                target: strongSelf,
                                                                selector: #selector(strongSelf
                                                                    .move(timer:appendToPendingTasks:)),
                                                                userInfo: ["time": time],
                                                                repeats: false)
            }
        }
    }
}
