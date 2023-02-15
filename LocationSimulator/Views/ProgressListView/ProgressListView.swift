//
//  ProgressListView.swift
//  Example
//
//  Created by David Klopp on 04.01.23.
//

import AppKit

let kRemoveDelay = 5.0

/**
 A list view that display tasks with a progressbar. 
 */
class ProgressListView: NSView, NSTableViewDelegate, NSTableViewDataSource {
    private(set) var tasks: [any ProgressTask] = []

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()

    private lazy var rowHeight: CGFloat = {
        let cell = ProgressEntryView()
        cell.progressText = { _ in "Placeholder" }
        cell.progress = 0
        cell.sizeToFit()
        return cell.frame.size.height
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented!")
    }

    private func setup() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.headerView = nil
        self.scrollView.backgroundColor = .clear
        self.scrollView.drawsBackground = false
        self.tableView.backgroundColor = .clear
        if #available(OSX 11.0, *) {
            self.tableView.gridStyleMask = .solidHorizontalGridLineMask
        }

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        self.tableView.addTableColumn(col)

        self.scrollView.documentView = self.tableView
        self.scrollView.hasHorizontalScroller = false
        self.scrollView.hasVerticalScroller = true
        self.scrollView.autohidesScrollers = true
        self.scrollView.borderType = .noBorder

        self.addSubview(self.scrollView)
    }

    override func layout() {
        super.layout()

        self.scrollView.frame = self.bounds
        self.tableView.frame.size.width = self.scrollView.bounds.width
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tasks.count
    }

    func reuseableCell(forRow row: Int) -> ProgressEntryView {
        let id = NSUserInterfaceItemIdentifier(rawValue: "cell")
        let cell = self.tableView.makeView(withIdentifier: id, owner: self) as? ProgressEntryView ?? ProgressEntryView()
        cell.identifier = id
        return cell
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let task = self.tasks[row]
        let cell = self.reuseableCell(forRow: row)
        cell.showProgress = task.showProgress
        cell.showSpinner = task.showSpinner
        if cell.showSpinner {
            cell.startSpinner()
        }

        cell.progressText = { progress in
            task.description(forProgress: Double(progress))
        }
        cell.setProgress(Float(task.progress), animated: false)

        let index = IndexSet(integer: row)
        (self.tasks as NSArray).addObserver(self, toObjectsAt: index, forKeyPath: "progress", context: nil)

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return self.rowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }

    func add(task: ProgressTask) {
        self.tableView.beginUpdates()
        let row = self.tasks.count
        self.tasks.append(task)
        let indexPath = IndexSet(integer: row)
        self.tableView.insertRows(at: indexPath, withAnimation: .slideUp)
        self.tableView.endUpdates()
    }

    func remove(task: ProgressTask) {
        guard let index = self.tasks.firstIndex(where: { $0 === task }) else { return }
        self.remove(taskAtIndex: index)
    }

    func remove(taskAtIndex index: Int) {
        guard index >= 0 else { return }

        self.tableView.beginUpdates()
        let indexPath = IndexSet(integer: index)
        (self.tasks as NSArray).removeObserver(self, fromObjectsAt: indexPath, forKeyPath: "progress")
        self.tasks.remove(at: index)
        self.tableView.removeRows(at: indexPath, withAnimation: .slideUp)
        self.tableView.endUpdates()
    }

    @objc private func update(info: [String: NSNumber]) {
        guard let index = info["index"]?.intValue, let progress = info["progress"]?.floatValue else { return }
        let cell = self.tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? ProgressEntryView
        cell?.setProgress(progress, animated: true)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "progress", let task = object as? ProgressTask else { return }
        // Note: This is sufficient for our use case, but not efficient if you decide to add thousands of tasks
        guard let index = self.tasks.firstIndex(where: { $0 === task }) else { return }

        // Use perform selector, this will work even if we are inside a DispatchQueue.main.async
        self.performSelector(onMainThread: #selector(self.update(info:)), with: [
            "index": NSNumber(value: index),
            "progress": NSNumber(value: Float(task.progress))
        ], waitUntilDone: false)
    }
}
