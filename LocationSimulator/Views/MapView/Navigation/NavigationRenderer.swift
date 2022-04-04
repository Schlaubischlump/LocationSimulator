//
//  NavigationRenderer.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import MapKit

@inline(__always)
private func lineBetween(point p0: MKMapPoint, andPoint p1: MKMapPoint, intersectRect rect: MKMapRect) -> Bool {
    let minX = min(p0.x, p1.x)
    let minY = min(p0.y, p1.y)
    let maxX = max(p0.x, p1.x)
    let maxY = max(p0.y, p1.y)

    let rect2 = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    return rect.intersects(rect2)
}

class NavigationRenderer: MKOverlayRenderer {
    /// The active, upcoming route fill color
    public var activeFill: NSColor
    /// The inactive, already traveled path fill color
    public var inactiveFill: NSColor?
    /// The border color around the path
    public var borderColor: NSColor?

    /// The line width to use
    public var lineWidth: CGFloat = 12.0
    /// The border width in percentage of the road width
    public var borderWidth: CGFloat = 0.4

    // MARK: Init

    /// Initializes a new NavigationRenderer from a given polyline.
    /// - Parameter polyline: The polyline to render
    /// - Parameter activeFill: The active path color
    public init(overlay: NavigationOverlay, activeFill: NSColor) {
        self.activeFill = activeFill

        super.init(overlay: overlay)
    }

    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let overlay = self.overlay as? NavigationOverlay

        let width = max(self.lineWidth/zoomScale, MKRoadWidthAtZoomScale(zoomScale))
        let borderWidth = width * (1.0 + self.borderWidth)

        let clipRect = mapRect.insetBy(dx: -borderWidth, dy: -borderWidth)

        var paths: (borderPath: CGMutablePath?, inactivePath: CGMutablePath?, activePath: CGMutablePath?)?
        overlay?.readCoordinatesAndWait { [weak self] inactiveRoute, activeRoute in
            paths = self?.calcultePaths(inactiveRoute: inactiveRoute, activeRoute: activeRoute,
                                          clipRect: clipRect, zoomScale: zoomScale)
        }

        guard overlay?.boundingMapRect.intersects(mapRect) ?? false, let paths = paths else {
            return
        }

        context.setMiterLimit(0)
        context.setLineJoin(CGLineJoin.round)
        context.setLineCap(CGLineCap.round)

        if let borderPath = paths.borderPath, let borderColor = self.borderColor, borderColor != .clear {
            context.addPath(borderPath)
            context.setLineWidth(borderWidth)
            context.setStrokeColor(borderColor.cgColor)
            context.strokePath()
        }

        context.setLineWidth(width)

        if let inactivePath = paths.inactivePath, let inactiveFill = inactiveFill, inactiveFill != .clear {
            context.addPath(inactivePath)
            context.setStrokeColor(inactiveFill.cgColor)
            context.strokePath()
        }

        if let activePath = paths.activePath {
            context.addPath(activePath)
            context.setStrokeColor(self.activeFill.cgColor)
            context.strokePath()
        }
    }

    // swiftlint:disable large_tuple
    @inline(__always)
    private func calculatePath(points: [CLLocationCoordinate2D], clipRect mapRect: MKMapRect,
                               zoomScale: MKZoomScale) -> CGMutablePath? {
        guard !points.isEmpty else {
            return nil
        }

        let path = CGMutablePath()

        // The fastest way to draw a path in an MKOverlayView is to simplify the geometry for the screen by omitting
        // any line segments that do not intersect the clipping rect. While it is possible to just add all the
        // points and let CoreGraphics handle clipping, it is much faster to do it yourself. Also make sure to only
        // include relevant points! If you use MKDirections you always only receive the minimum necessary waipoints.
        var needsMove = true

        var lastPoint = MKMapPoint(points[0])
        for i in 1..<points.count {
            let point = MKMapPoint(points[i])

            if lineBetween(point: point, andPoint: lastPoint, intersectRect: mapRect) {
                if needsMove {
                    path.move(to: self.point(for: lastPoint))
                }
                path.addLine(to: self.point(for: point))
                needsMove = false
            } else {
                needsMove = true
            }

            lastPoint = point
        }

        return path
    }

    private func calcultePaths(inactiveRoute: [CLLocationCoordinate2D],
                               activeRoute: [CLLocationCoordinate2D],
                               clipRect mapRect: MKMapRect,
                               zoomScale: MKZoomScale)
    -> (borderPath: CGMutablePath?, inactivePath: CGMutablePath?, activePath: CGMutablePath?) {
        return (self.calculatePath(points: inactiveRoute + activeRoute, clipRect: mapRect, zoomScale: zoomScale),
                self.calculatePath(points: inactiveRoute, clipRect: mapRect, zoomScale: zoomScale),
                self.calculatePath(points: activeRoute, clipRect: mapRect, zoomScale: zoomScale))
    }
    // swiftlint:enable large_tuple
}
