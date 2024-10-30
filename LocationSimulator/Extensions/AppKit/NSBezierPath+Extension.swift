//
//  NSBezierPath+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 19.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSBezierPath {

    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)

        for idx in 0 ..< self.elementCount {
            let type = self.element(at: idx, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            default:
                break
            }
        }

        return path
    }
}
