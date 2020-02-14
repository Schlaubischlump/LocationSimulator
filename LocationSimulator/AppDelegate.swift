//
//  AppDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - MenuBar

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

    @IBAction func setMovementSpeed(_ menuItem: NSMenuItem) {
        // Only these tags are allowed, otherwise the app would crash
        guard [kWalkTag, kCycleTag, kDriveTag].contains(menuItem.tag) else { return }
        // Change the movement speed.
        guard let windowController = NSApp.mainWindow?.windowController as? WindowController else { return }
        windowController.typeSegmented.selectedSegment = menuItem.tag
        windowController.typeSegmentChanged(windowController.typeSegmented)
    }

    @IBAction func pauseResumeNavigation(_ menuItem: NSMenuItem) {
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }
        viewController.spoofer?.pauseResumeAutoMove()
    }

    @IBAction func move(_ menuItem: NSMenuItem) {
        guard let windowController = NSApp.mainWindow?.windowController else { return }
        guard let viewController = windowController.contentViewController as? MapViewController else { return }

        switch(menuItem.tag) {
            case kLeftTag:
                viewController.rotateHeaderViewBy(CGFloat(5.0.degreesToRadians))
                break

            case kRightTag:
                viewController.rotateHeaderViewBy(CGFloat(-5.0.degreesToRadians))
                break

            //  x | x                 |          |                   |
            // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
            //    |    arrow down   x | x      x | x  arrow down   x | x
            case kDownTag:
                if viewController.spoofer?.moveState == .manual {
                    let angle = viewController.getHeaderViewAngle()
                    if (angle < .pi/2.0 && angle > -.pi/2.0) {
                        viewController.rotateHeaderViewBy(.pi)
                    }
                    viewController.spoofer?.move(appendToPendingTasks: false)
                }
                break

            //    |                 x | x      x | x               x | x
            // ---|--- ==========> ---|--- or ---|--- ==========> ---|---
            //  x | x   arrow up      |          |     arrow up      |
            case kUpTag:
                if viewController.spoofer?.moveState == .manual {
                    let angle = viewController.getHeaderViewAngle()
                    if (angle > .pi/2.0 || angle < -.pi/2.0) {
                        viewController.rotateHeaderViewBy(.pi)
                    }
                    viewController.spoofer?.move(appendToPendingTasks: false)
                }
                break
        default:
            break
        }
    }

}
