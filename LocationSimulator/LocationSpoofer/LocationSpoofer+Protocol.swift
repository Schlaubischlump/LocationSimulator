//
//  LocationSpoofer+Protocol.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationSpooferDelegate: AnyObject {
    /// Called when the `moveType` is about to change.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter moveState: the new moveState
    func willChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType)

    /// Called when the `moveType` did change.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter moveState: the new moveType
    func didChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType)

    /// Called when the `moveState` state is about to change.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter moveState: the new moveState
    func willChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState)

    /// Called when the `moveState` state did change.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter moveState: the new moveState
    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState)

    /// Called when the location is about to change.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter toCoordinate: the new location which will be set or nil if the loction will be reseted
    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?)

    /// Called when the location was changed.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter toCoordinate: the new location or nil if the loction was reset
    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?)

    /// Called when an error occured will changing the location.
    /// - Parameter spoofer: instance of the location spoofer
    /// - Parameter toCoordinate: the new location which should be set or nil if the loction should be reset
    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?)

    /// Called when a currently running navigation is about to be paused.
    /// - Parameter spoofer: instance of the location spoofer
    func willPauseNavigation(spoofer: LocationSpoofer)

    /// Called when a currently running navigation is paused.
    /// - Parameter spoofer: instance of the location spoofer
    func didPauseNavigation(spoofer: LocationSpoofer)

    /// Called when a currently running navigation is about to be resumed.
    /// - Parameter spoofer: instance of the location spoofer
    func willResumeNavigation(spoofer: LocationSpoofer)

    /// Called when a currently running navigation is resumed.
    /// - Parameter spoofer: instance of the location spoofer
    func didResumeNavigation(spoofer: LocationSpoofer)
}

extension LocationSpooferDelegate {
    func willChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType) {}
    func didChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType) {}

    func willChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {}
    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {}

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}
    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}

    func willResumeNavigation(spoofer: LocationSpoofer) {}
    func didResumeNavigation(spoofer: LocationSpoofer) {}

    func willPauseNavigation(spoofer: LocationSpoofer) {}
    func didPauseNavigation(spoofer: LocationSpoofer) {}

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}
}
