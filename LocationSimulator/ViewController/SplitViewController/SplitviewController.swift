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

                // Show the MapView behind the sidebar if we got a MapView
                if viewController as? MapViewController != nil {
                    self.apply(sidebarStyle: .inFrontOfMap, forDetailViewController: viewController)
                } else {
                    self.apply(sidebarStyle: .standard, forDetailViewController: viewController)
                }
            } else {
                // nil => remove the detail view controller.
                self.splitViewItems = items.dropLast()
            }
        }
    }

    /// Readonly sidebar view controller
    public var sidebarViewController: SidebarViewController? {
        let items = self.splitViewItems
        return items.count >= 1 ? items[0].viewController as? SidebarViewController : nil
    }

    /// True if the sidebar is collapse, false otherwise.
    public private(set) var isSidebarCollapsed: Bool = false

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.wantsLayer = true

        // Configure the sidebar width.
        if #available(OSX 11.0, *) {
            self.sidebarSplitViewItem.allowsFullHeightLayout = true
            self.sidebarSplitViewItem.titlebarSeparatorStyle = .none
        }
        self.sidebarSplitViewItem.minimumThickness = kMinimumSidebarWidth
        self.sidebarSplitViewItem.maximumThickness = 250
    }

    // MARK: - Sidebar style

    func updateForDeviceStatus(_ status: DeviceStatus) {
        let deviceConnected = (status == .connected)
        let deviceDisconnected = (status == .disconnected)
        self.sidebarViewController?.searchEnabled = !deviceDisconnected

        // Clear the searchField.
        if deviceDisconnected || deviceConnected {
            self.sidebarViewController?.clearSearchField()
        }
    }

    /// Apply a specific custom style to the sidebar.
    /// Note: This functions is obsolete if Apple provides a default way to overlay a sidebar.
    /// - Parameter style: the style to apply to the sidebar
    /// - Parameter forDetailViewController: the current detailViewController
    private func apply(sidebarStyle: SidebarStyle, forDetailViewController detailViewController: NSViewController) {
        guard let mapViewController = detailViewController as? MapViewController,
              let mapView = mapViewController.mapView else {
            return
        }

        guard #available(OSX 11.0, *) else {
            // Only fill the detailViewController on catalina and below
            // Note: MapView has no leading constraint defined in interface builder at compile time
            let leading = mapView.leadingAnchor.constraint(equalTo: detailViewController.view.leadingAnchor)
            leading.isActive = true
            return
        }

        // Change the effectView to our liking
        self.sidebarViewController?.apply(sidebarStyle: sidebarStyle)

        // configure the mapView to always fill the complete splitView
        let leading = mapView.leadingAnchor.constraint(equalTo: self.splitView.leadingAnchor)
        leading.isActive = true

        // Allow drawing out of bounds
        var superView: NSView? = mapView
        while superView != nil {
            superView?.wantsLayer = true
            superView?.layer?.masksToBounds = false
            superView = superView?.superview
        }

        // Reverse the ordering of the splitView items viewController to position detailViewController behind  siderbar
        self.splitView.sortSubviews({ (view1, view2, _) in
            let splitView = view1.superview as? NSSplitView
            let arrangedViews = splitView?.arrangedSubviews
            if view1 == arrangedViews?.first && view2 == arrangedViews?.last {
                return .orderedDescending
            }
            return .orderedAscending
        }, context: nil)
    }

    // MARK: - Toggle Sidebar

    public override func toggleSidebar(_ sender: Any?) {
        self.isSidebarCollapsed = !self.isSidebarCollapsed
        super.toggleSidebar(nil)
    }

    public func toggleSidebar() {
        self.toggleSidebar(nil)
    }

    // MARK: - NSSplitViewDelegate

    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }

    // Ugly fix to show the divider on macOS 11 and 12
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect,
                            forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {

        // Don't do anything for macOS versions lower than 11.0
        guard #available(macOS 11.0, *) else { return drawnRect }
        // Don't do anything for macOS versions greater than 13.0
        guard #unavailable(macOS 13.0) else { return drawnRect }

        // Get a reference to the content view
        let mapViewController = self.detailViewController as? MapViewController
        guard let mapView = mapViewController?.mapView else {
            return drawnRect
        }

        // This assume the mapView has the same frame as the splitView
        let rect = drawnRect
        if rect.minX < kMinimumSidebarWidth {
            mapView.layer?.mask = nil
        } else {
            let width = self.splitView.bounds.width
            let leftSide = CGRect(x: 0, y: 0, width: rect.minX, height: rect.height)
            let rightSide = CGRect(x: rect.minX+rect.width, y: 0, width: width - rect.minX, height: rect.height)

            // Cut out a line from the mapView, where the border is
            let path = CGMutablePath(rect: leftSide, transform: .none)
            path.addPath(CGPath(rect: rightSide, transform: .none))

            let maskLayer = CAShapeLayer()
            maskLayer.path = path
            maskLayer.backgroundColor = .black
            maskLayer.fillRule = .evenOdd

            mapView.layer?.mask = maskLayer
        }

        return drawnRect
    }
}
