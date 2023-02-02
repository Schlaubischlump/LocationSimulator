//
//  AppDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var menubarController: MenubarController!

    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.menubarController.loadDefaults()

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMove(notification:)),
                                               name: NSWindow.didMoveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)),
                                               name: NSWindow.willCloseNotification, object: nil)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // We do not want to present the donation and intro window at the same time.
        if !self.openOnboardingScreenOnFirstLaunch() {
            self.openInfoViewOnVersionUpdate()
        }
    }

    /// Open the InfoViewController when the version number changed. This way we can inform the user about critical
    /// changes and remind him/her to donate ;)
    @discardableResult
    private func openInfoViewOnVersionUpdate() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.lastAppVersion != kAppVersion {
            // FIXME: Segue would be nicer, but does not work
            AppMenubarItem.preferences.triggerAction()
            // Update the last app version
            defaults.lastAppVersion = kAppVersion
            return true
        }
        return false
    }

    @discardableResult
    private func openOnboardingScreenOnFirstLaunch() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.firstLaunch, self.onboardingWindow == nil else {
            return false
        }

        let pages = [
            OnboardPageSidebarViewController(),
            OnboardPageMapViewController(),
            OnboardPageToolbarViewController(),
            OnboardPageFinishViewController()
        ]
        let onboardingVC = OnboardViewController(pages: pages)

        let window = NSWindow(contentViewController: onboardingVC)
        window.title = "WELCOME".localized
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.styleMask = [.titled, .fullSizeContentView, .closable]

        var rect = window.contentRect(forFrameRect: window.frame)
        rect.size = CGSize(width: 400, height: 400)
        let frame = window.frameRect(forContentRect: rect)
        window.setFrame(frame, display: true, animate: true)

        if let mainWindow = NSApplication.shared.windows.first(where: { window in
            (window.windowController as? WindowController) != nil
        }) {
            mainWindow.center()
            window.center(inWindow: mainWindow)
        }

        self.onboardingWindow = window

        NSApplication.shared.runModal(for: window)

        defaults.firstLaunch = false

        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Reset the location for every device that currently has a spoofed location. We are not interested in updating
        // any window UI, since we are closing the app. We therefore directly access the device and make a synchronous
        // call to reset the location.
        NSApplication.shared.windows.forEach { window in
            let windowController = window.windowController as? WindowController
            let device = windowController?.mapViewController?.device
            device?.disableSimulation()
        }
    }

    @objc func windowDidMove(notification: Notification) {
        // only react to main window movement
        guard let window = notification.object as? NSWindow, window.windowController as? WindowController != nil else {
            return
        }
        self.onboardingWindow?.center(inWindow: window, animate: true)
    }

    @objc func windowWillClose(notification: Notification) {
        // Correctly close the onboarding window
        guard notification.object as? NSWindow == self.onboardingWindow else {
            return
        }
        self.onboardingWindow = nil
        NSApplication.shared.stopModal(withCode: .cancel)
    }
}
