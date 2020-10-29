//
//  PreferenceTabViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 29.10.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

/// TabViewController subclass which automatically resizes the window depending on the tab.
class PreferencesTabViewController: NSTabViewController {

    private lazy var tabViewSizes: [NSTabViewItem: NSSize] = [:]

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)

        if let tabViewItem = tabViewItem {
            self.view.window?.title = tabViewItem.label
            self.resizeWindowToFit(tabViewItem: tabViewItem)
        }
    }

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)

        // Cache the size of the tab view.
        if let tabViewItem = tabViewItem, let size = tabViewItem.view?.frame.size {
            self.tabViewSizes[tabViewItem] = size
        }
    }

    /// Resizes the window to fit the content of the tab.
    private func resizeWindowToFit(tabViewItem: NSTabViewItem) {
        guard let size = self.tabViewSizes[tabViewItem],
              let window = self.view.window else { return }

        let contentRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let contentFrame = window.frameRect(forContentRect: contentRect)
        let toolbarHeight = window.frame.size.height - contentFrame.size.height
        let newOrigin = NSPoint(x: window.frame.origin.x, y: window.frame.origin.y + toolbarHeight)
        let newFrame = NSRect(origin: newOrigin, size: contentFrame.size)
        window.setFrame(newFrame, display: false, animate: true)
    }
}
