//
//  ProgressListView.swift
//  Example
//
//  Created by David Klopp on 04.01.23.
//

import AppKit

let kRemoveDelay = 5.0

extension ProgressTask {
    fileprivate func clear() {
        self.onError = nil
        self.onProgress = nil
        self.onCompletion = nil
    }
}

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
        self.tableView.gridStyleMask = .solidHorizontalGridLineMask

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        self.tableView.addTableColumn(col)

        self.scrollView.documentView = self.tableView
        self.scrollView.hasHorizontalScroller = false
        self.scrollView.hasVerticalScroller = true
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

        // This causes problems... don't know why. We guard the guard cell?.task === task instead
        // which isn't perfect since it requires object identity.
        // cell.task?.onProgress = nil
        // cell.task = nil

        return cell
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let task = self.tasks[row]
        let cell = self.reuseableCell(forRow: row)
        cell.task = task
        cell.showProgress = task.showProgress
        cell.showSpinner = task.showSpinner
        if cell.showSpinner {
            cell.startSpinner()
        }

        cell.progressText = { progress in
            task.description(forProgress: progress)
        }
        cell.setProgress(task.progress, animated: false)

        task.onProgress = { [weak cell] progress in
            guard cell?.task === task else { return }
            DispatchQueue.main.async {
                cell?.progress = progress
            }
        }
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
        self.tasks.append(task)
        let indexPath = IndexSet(integer: self.tasks.count - 1)
        self.tableView.insertRows(at: indexPath, withAnimation: .slideUp)

        // make sure we always clean up, even if no cell is created
        task.onCompletion = { [weak self, weak task] _ in
            guard let task = task  else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + kRemoveDelay) {
                self?.remove(task: task)
            }
        }
        task.onError = { [weak self, weak task] _ in
            guard let task = task else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + kRemoveDelay) {
                self?.remove(task: task)
            }
        }
        self.tableView.endUpdates()
    }

    func remove(task: ProgressTask) {
        self.tableView.beginUpdates()
        defer {
            self.tableView.endUpdates()
        }
        guard let index = self.tasks.firstIndex(where: { $0 === task }) else { return }
        let taskToRemove = self.tasks.remove(at: index)
        taskToRemove.clear()
        let indexPath = IndexSet(integer: index)
        self.tableView.removeRows(at: indexPath, withAnimation: .slideUp)

    }

    func remove(taskAtIndex index: Int) {
        self.tableView.beginUpdates()
        defer {
            self.tableView.endUpdates()
        }
        guard index >= 0 else { return }
        let taskToRemove = self.tasks.remove(at: index)
        taskToRemove.clear()
        let indexPath = IndexSet(integer: index)
        self.tableView.removeRows(at: indexPath, withAnimation: .slideUp)
    }
}
