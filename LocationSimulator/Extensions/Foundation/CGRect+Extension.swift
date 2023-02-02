//
//  CGRect+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 02.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension CGRect {
    func inset(by theInsets: NSEdgeInsets) -> CGRect {
        var frame = self
        frame.size.width -= theInsets.left + theInsets.right
        frame.size.height -= theInsets.bottom + theInsets.top
        frame.origin.x += theInsets.left
        frame.origin.y += theInsets.bottom
        return frame
    }
}
