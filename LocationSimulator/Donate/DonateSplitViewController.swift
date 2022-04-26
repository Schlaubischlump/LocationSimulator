//
//  DonateSplitViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class DonateSplitViewController: NSSplitViewController {
    /// A reference to the current detail view controller.
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the sidebar width.
        let sidebarSplitViewItem = self.splitViewItems[0]
        if #available(OSX 11.0, *) {
            sidebarSplitViewItem.allowsFullHeightLayout = true
            sidebarSplitViewItem.titlebarSeparatorStyle = .none
        }
        sidebarSplitViewItem.minimumThickness = 180
        sidebarSplitViewItem.maximumThickness = 180
    }
}
