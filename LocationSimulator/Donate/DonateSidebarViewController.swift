//
//  DonateSidebarViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

let kTableRowHeight: CGFloat = 34.0

class DonateSidebarViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        // Fix the layout for older macOS versions
        let scrollView = self.tableView.enclosingScrollView
        if #available(macOS 11.0, *) {
            scrollView?.automaticallyAdjustsContentInsets = true
        } else {
            scrollView?.automaticallyAdjustsContentInsets = false
            scrollView?.contentInsets = NSEdgeInsets(top: 25, left: 0, bottom: 0, right: 0)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if self.tableView.selectedRow < 0 {
            self.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
}

extension DonateSidebarViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DonateMethod.enabledCases.count
    }
}

extension DonateSidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return kTableRowHeight
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier,
              let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        let donateMethod = DonateMethod.enabledCases[row]
        cell.textField?.stringValue = donateMethod.name
        cell.imageView?.wantsLayer = true
        cell.imageView?.layer?.backgroundColor = .white
        cell.imageView?.layer?.cornerRadius = 5.0
        cell.imageView?.image = donateMethod.icon
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard notification.object as? NSTableView == self.tableView else { return }

        let selectedRow = self.tableView.selectedRow
        guard selectedRow >= 0 else { return }

        // Create and assign a new detail view controller
        let vc = self.storyboard?.instantiateController(withIdentifier: "DonateDetailViewController")
        let detailViewController = vc as? DonateDetailViewController
        detailViewController?.donateMethod = DonateMethod.enabledCases[selectedRow]

        let donateSplitViewController = self.enclosingSplitViewController as? DonateSplitViewController
        donateSplitViewController?.detailViewController = detailViewController
    }
}
