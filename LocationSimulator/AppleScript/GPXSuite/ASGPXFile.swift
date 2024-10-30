//
//  ASGPXFile.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import GPXParser

@objc(ASWayPoint) class ASWayPoint: IndexedContainerItem {
    @objc let latitude: CGFloat
    @objc let longitude: CGFloat
    @objc let name: String
    @objc var coordinate: [CGFloat] {
        return [self.latitude, self.longitude]
    }

    init(waypoint: WayPoint, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.latitude = waypoint.coordinate.latitude
        self.longitude = waypoint.coordinate.longitude
        self.name = waypoint.name ?? ""
        super.init(key: "waypoints", atIndex: atIndex, inContainer: inContainer)
    }
}

@objc(ASTrackPoint) class ASTrackPoint: IndexedContainerItem {
    @objc let latitude: CGFloat
    @objc let longitude: CGFloat
    @objc let name: String
    @objc var coordinate: [CGFloat] {
        return [self.latitude, self.longitude]
    }

    init(point: TrackPoint, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.latitude = point.coordinate.latitude
        self.longitude = point.coordinate.longitude
        self.name = point.name ?? ""
        super.init(key: "points", atIndex: atIndex, inContainer: inContainer)
    }
}

@objc(ASTrackSegment) class ASTrackSegment: IndexedContainerItem {
    @objc let name: String
    @objc private(set) var points: [ASTrackPoint] = []

    init(segment: TrackSegment, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.name = segment.name ?? ""
        super.init(key: "segments", atIndex: atIndex, inContainer: inContainer)
        self.points = segment.trackpoints.enumerated().compactMap { [weak self] (index, pt) in
            guard let `self` = self else { return nil }
            return ASTrackPoint(point: pt, atIndex: index, inContainer: self.objectSpecifier)
        }
    }
}

@objc(ASTrack) class ASTrack: IndexedContainerItem {
    @objc let name: String
    @objc private(set) var segments: [ASTrackSegment] = []

    init(track: Track, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.name = track.name ?? ""
        super.init(key: "tracks", atIndex: atIndex, inContainer: inContainer)
        self.segments = track.segments.enumerated().compactMap { [weak self] (index, seg) in
            guard let `self` = self else { return nil }
            return ASTrackSegment(segment: seg, atIndex: index, inContainer: self.objectSpecifier)
        }
    }
}

@objc(ASRoutePoint) class ASRoutePoint: IndexedContainerItem {
    @objc let latitude: CGFloat
    @objc let longitude: CGFloat
    @objc var coordinate: [CGFloat] {
        return [self.latitude, self.longitude]
    }
    @objc let name: String

    init(point: RoutePoint, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.latitude = point.coordinate.latitude
        self.longitude = point.coordinate.longitude
        self.name = point.name ?? ""
        super.init(key: "points", atIndex: atIndex, inContainer: inContainer)
    }
}

@objc(ASRoute) class ASRoute: IndexedContainerItem {
    @objc let name: String
    @objc private(set) var points: [ASRoutePoint] = []

    init(route: Route, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.name = route.name ?? ""
        super.init(key: "routes", atIndex: atIndex, inContainer: inContainer)
        self.points = route.routepoints.enumerated().compactMap { [weak self] (index, pt) in
            guard let `self` = self else { return nil }
            return ASRoutePoint(point: pt, atIndex: index, inContainer: self.objectSpecifier)
        }
    }
}

/// A wrapper around a GPX file. The file will be parsed synchronously on init.
@objc(ASGPXFile) class ASGPXFile: NSObject {
    @objc let file: URL

    static var openFiles: [ASGPXFile] = []

    @objc let waypoints: [ASWayPoint]
    @objc let tracks: [ASTrack]
    @objc let routes: [ASRoute]

    private let specifier: NSScriptObjectSpecifier?

    @objc let uniqueID: String

    override var objectSpecifier: NSScriptObjectSpecifier? {
        self.specifier
    }

    init(file: URL) throws {
        self.file = file
        let parser = try GPXParser(file: file)

        let semaphore = DispatchSemaphore(value: 0)
        var error: Error?

        parser.parse { result in
            switch result {
            case .success:
                semaphore.signal()
            case .failure(let err):
                error = err
                semaphore.signal()
            }
        }

        // Wait for the async task to finish... This will block
        semaphore.wait()

        // Async task has failed
        if let error = error {
            throw error
        }

        // Async task was successfull => Load all waypoints, tracks etc.
        guard let appDescription = NSApp.classDescription as? NSScriptClassDescription else {
            throw ASError.MissingClassDescription
        }

        // Apple script does not like big integer values generated by hashes...
        // Thats why we use this workaround
        let id = UUID().uuidString
        self.uniqueID = id
        let container = NSUniqueIDSpecifier(containerClassDescription: appDescription,
                                            containerSpecifier: nil, key: "gpxFiles",
                                            uniqueID: id)

        self.specifier = container
        self.waypoints = parser.waypoints.enumerated().map { (index, wp) in
            ASWayPoint(waypoint: wp, atIndex: index, inContainer: container)
        }
        self.tracks = parser.tracks.enumerated().map { (index, track) in
            ASTrack(track: track, atIndex: index, inContainer: container)
        }
        self.routes = parser.routes.enumerated().map { (index, route) in
            ASRoute(route: route, atIndex: index, inContainer: container)
        }

        super.init()

        // Keep a reference to this class
        // If we don't keep a reference, AppleScript is not able to access properties of an instance
        ASGPXFile.openFiles += [self]
    }

    @objc(close:) private func close(_ command: NSScriptCommand) {
        ASGPXFile.openFiles.removeAll { [weak self] in
            return $0.uniqueID == self?.uniqueID
        }
    }
}
