//
//  CoordinateValueTransformer.swift
//  LocationSimulator
//
//  Created by David Klopp on 31.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

// Value transformer used when the textfield is cleared. We fall back to a default value.
@objc(LSLatitudeValueTransformer) class LatitudeValueTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value {
            return value
        }
        return 37.3305976
    }
}

// Value transformer used when the textfield is cleared. We fall back to a default value.
@objc(LSLongitudeValueTransformer) class LongitudeValueTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value {
            return value
        }
        return -122.0265794
    }
}
