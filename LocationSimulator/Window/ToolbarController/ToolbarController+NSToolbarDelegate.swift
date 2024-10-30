//
//  ToolbarController+NSToolbarDelegate.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension NSToolbarItem.Identifier {
    static let autoFocus = NSToolbarItem.Identifier("autoFocus")
    static let autoReverse = NSToolbarItem.Identifier("autoReverse")
    static let currentLocation = NSToolbarItem.Identifier("currentLocation")
    static let moveType = NSToolbarItem.Identifier("moveType")
    static let reset = NSToolbarItem.Identifier("reset")
    static let search = NSToolbarItem.Identifier("search")
    static let speed = NSToolbarItem.Identifier("speed")
}

extension ToolbarController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if #available(macOS 11.0, *) {
            // add the searchbar to the left side of the toolbar
            return [
                .flexibleSpace, .toggleSidebar, .sidebarTrackingSeparator,
                .reset, .currentLocation, .autoFocus, .autoReverse, .flexibleSpace,
                .speed, .flexibleSpace,
                .moveType
            ]
        }

        // position the searchbar directly in the toolbar on older macOS versions
        return [
            .toggleSidebar, .flexibleSpace,
            .reset, .currentLocation, .space,
            .search, .flexibleSpace, .moveType
        ]
    }

    /*
    // Called to late... Interface builder already added all of those
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let items: [NSToolbarItem.Identifier] = [
            .toggleSidebar, .autoFocus, .autoReverse,
            .currentLocation, .moveType, .reset, .speed
        ]
        // MacOS 11.0 has the searchbar in the sidebar
        if #available(macOS 11.0, *) {
            return items
        }
        return items + [.search]
    }*/

    /**
     * Disable the search item if we added the search to the sidebar.
     * We would need to generate the search item in code to disable it on > macOS 11.0 in general.
     * The toolbar delegate only appends to the allowed items of interface builder.
     */
    @available(macOS 13.0, *)
    func toolbarImmovableItemIdentifiers(_ toolbar: NSToolbar) -> Set<NSToolbarItem.Identifier> {
        return kEnableSidebarSearchField ? [.search, .toggleSidebar] : [.toggleSidebar]
    }
}
