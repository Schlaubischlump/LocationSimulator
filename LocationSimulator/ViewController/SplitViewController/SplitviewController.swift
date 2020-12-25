//
//  SplitviewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

class SplitViewController: NSSplitViewController {
    @IBOutlet var sidebarSplitViewItem: NSSplitViewItem!

    /// A reference to the current detail view controller. This can be the `NoDeviceViewController` or the
    /// `MapViewController`. Use this variable to change the detailViewController.
    public var detailViewController: NSViewController? {
        get {
            let items = self.splitViewItems
            return items.count >= 2 ? items[1].viewController : nil
        }

        set (newValue) {
            var items = self.splitViewItems
            if let viewController = newValue {
                // Load a new detail view controller.
                let detailedItem = NSSplitViewItem(viewController: viewController)
                if items.count < 2 {
                    items.append(detailedItem)
                } else {
                    items[1] = detailedItem
                }
                self.splitViewItems = items
            } else {
                // nil => remove the detail view controller.
                self.splitViewItems = items.dropLast()
            }
        }
    }

    /// Readonly sidebar view controller
    public var sidebarViewController: NSViewController? {
        let items = self.splitViewItems
        return items.count >= 1 ? items[0].viewController : nil
    }

    /// True if the sidebar is collapse, false otherwise.
    public private(set) var isSidebarCollapsed: Bool = false

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the sidebar width.
        if #available(OSX 11.0, *) {
            self.sidebarSplitViewItem.allowsFullHeightLayout = true
        }
        self.sidebarSplitViewItem.minimumThickness = 150
        self.sidebarSplitViewItem.maximumThickness = 200
    }

    // MARK: - Toggle Sidebar

    public override func toggleSidebar(_ sender: Any?) {
        self.isSidebarCollapsed = !self.isSidebarCollapsed
        super.toggleSidebar(nil)
    }

    public func toggleSidebar() {
        self.toggleSidebar(nil)
    }

    // MARK: NSSplitViewDelegate

    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
}
