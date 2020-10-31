//
//  AppDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa
import CoreLocation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // load all recent locations menubaritems
        let items = RecentLocationMenubarItem.locations()
        items.reversed().forEach { item in
            RecentLocationMenubarItem.addLocationMenuItem(item)
        }
        // enable the clear menu item if required
        if items.count > 0 {
            RecentLocationMenubarItem.clearMenu.enable()
        }
    }

    //func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - MenuBar

    /// Show the user a dialog to enter the coordinates to go to.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func setLocation(_ menuItem: NSMenuItem) {
        // Show the user an input textField to change the location.
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        // We can only request one location change at a time.
        if viewController.isShowingAlert {
            NSSound.beep()
        } else {
            viewController.requestTeleportOrNavigation()
        }
    }

    /// Change the current movement speed (walk / cylcle / drive).
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func setMovementSpeed(_ menuItem: NSMenuItem) {
        // Only these tags are allowed, otherwise the app would crash.
        guard let item = NavigationMenubarItem(rawValue: menuItem.tag),
            item == .walk || item == .cycle || item == .drive else {
            return
        }
        // Change the movement speed.
        guard let windowController = NSApp.mainWindow?.windowController as? WindowController else { return }
        windowController.typeSegmented.selectedSegment = menuItem.tag
        windowController.typeSegmentChanged(windowController.typeSegmented)
    }

    /// Pause or resume the current navigation, if a navigation is active. Otherwise do nothing.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func pauseResumeNavigation(_ menuItem: NSMenuItem) {
        // pause or resume the navigation or start and stop automove if we are not navigating
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        guard let spoofer = viewController.spoofer else { return }

        // start automoving
        if spoofer.moveState == .manual {
            spoofer.moveState = .auto
            spoofer.move()
        } else if spoofer.moveState == .auto {
            // stop automove
            if spoofer.route.isEmpty {
                spoofer.moveState = .manual
            } else {
                // pause / resume the navigation
                spoofer.pauseResumeAutoMove()
            }
        }
    }

    /// Change the current location by going north (up) / south (down) or change the current heading (left / right).
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func move(_ menuItem: NSMenuItem) {
        guard let windowController = NSApp.mainWindow?.windowController,
            let viewController = windowController.contentViewController as? MapViewController else { return }

        switch NavigationMenubarItem(rawValue: menuItem.tag) {
        // Counterclockwise
        case .moveCounterclockwise:
            viewController.rotateHeaderViewBy(CGFloat(5.0.degreesToRadians))
        // Clockwise
        case .moveClockwise:
            viewController.rotateHeaderViewBy(CGFloat(-5.0.degreesToRadians))
        //  x | x                 |          |                   |
        // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
        //    |    arrow down   x | x      x | x  arrow down   x | x
        case .moveDown:
            if viewController.spoofer?.moveState == .manual {
                let angle = viewController.getHeaderViewAngle()
                if angle < .pi/2.0 && angle > -.pi/2.0 {
                    viewController.rotateHeaderViewBy(.pi)
                }
                viewController.spoofer?.move(appendToPendingTasks: false)
            }
        //    |                 x | x      x | x               x | x
        // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
        //  x | x   arrow up      |          |     arrow up      |
        case .moveUp:
            if viewController.spoofer?.moveState == .manual {
                let angle = viewController.getHeaderViewAngle()
                if angle > .pi/2.0 || angle < -.pi/2.0 {
                    viewController.rotateHeaderViewBy(.pi)
                }
                viewController.spoofer?.move(appendToPendingTasks: false)
            }
        default:
            break
        }
    }

    /// Stop the current navigation, if a navigation is active.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func stopNavigation(_ sender: NSMenuItem) {
        // stop the navigation
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        viewController.spoofer?.moveState = .manual
    }

    /// Stop spoofing the location and reset it to the actual device location.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func resetLocation(_ sender: NSMenuItem) {
        // reset the current location to the device location
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        viewController.spoofer?.resetLocation()
    }

    /// Clear the `Recent locations` menu by removing all its stored entries.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @IBAction func clearRecentLocations(_ sender: NSMenuItem) {
        RecentLocationMenubarItem.clearLocations()
    }

    /// Change the current location to the coordinates defined by a recently visited location.
    /// - Parameter menuItem: the selected menu item that triggered this function
    @objc func selectRecentLocation(_ sender: NSMenuItem) {
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        guard let idx: Int = RecentLocationMenubarItem.menu?.items.firstIndex(of: sender) else { return }
        let loc: Location = RecentLocationMenubarItem.locations()[idx]
        let coord = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        if viewController.spoofer?.currentLocation != nil {
            viewController.requestTeleportOrNavigation(toCoordinate: coord)
        } else {
            viewController.spoofer?.setLocation(coord)
        }
    }
}
