//
//  Float+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 13.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation

extension CGFloat {
    public func limitedBy(min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        return CGFloat.maximum(minValue, CGFloat.minimum(self, maxValue))
    }
}
