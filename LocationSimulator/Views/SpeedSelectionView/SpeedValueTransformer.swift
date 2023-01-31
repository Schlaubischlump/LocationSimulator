//
//  SpeedValueTransformer.swift
//  LocationSimulator
//
//  Created by David Klopp on 31.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

// Value transformer used when the textfield is cleared. We fall back to a default value.
@objc(LSSpeedValueTransformer) class SpeedValueTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value {
            return value
        }
        return kMinSpeed
    }
}
