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
}

extension LocationSpooferDelegate {
    func willChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType) {}
    func didChangeMoveType(spoofer: LocationSpoofer, moveType: MoveType) {}

    func willChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {}
    func didChangeMoveState(spoofer: LocationSpoofer, moveState: MoveState) {}

    func willChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}
    func didChangeLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}

    func errorChangingLocation(spoofer: LocationSpoofer, toCoordinate: CLLocationCoordinate2D?) {}
}
