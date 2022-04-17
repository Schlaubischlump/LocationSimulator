//
//  LocationSpoofer+Extensio.swift
//  LocationSimulator
//
//  Created by David Klopp on 06.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation
import LocationSpoofer

extension LocationSpoofer {
    func switchToInteractiveMoveState() {
        self.stopAutoUpdate()
        self.moveState = .manual
    }

    func switchToAutoMoveState() {
        self.stopAutoUpdate()
        self.moveState = .auto
    }

    func switchToNavigationState(_ route: [CLLocationCoordinate2D]) {
        self.stopAutoUpdate()
        self.moveState = .navigation(route: NavigationRoute(route))
    }
}
