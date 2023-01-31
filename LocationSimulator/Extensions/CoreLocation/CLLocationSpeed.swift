//
//  CLLocationSpeed.swift
//  LocationSimulator
//
//  Created by David Klopp on 31.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import CoreLocation

extension CLLocationSpeed {
    init(inKmH speed: Double) {
        self = (speed * 1000)/(60*60)
    }

    var inKmH: Double {
        return (self * (60 * 60)) / 1000
    }
}
