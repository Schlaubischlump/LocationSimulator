//
//  LoggerViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 12.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

struct LogLine {
    let row: Int
    let time: String
    let level: String
    let thread: String
    let message: String

    init?(row: Int, line: String) {
        let components: [String] = line.split(separator: "]", maxSplits: 3).map {
            $0[$0.index(after: $0.startIndex)...].trimmingCharacters(in: .whitespaces)
        }

        if components.count != 4 {
            return nil
        }

        self.row = row
        self.time = components[0]
        self.level = components[1]
        self.thread = components[2]
        self.message = components[3]
    }

    public var levelColor: NSColor {
        switch self.level {
        case "INFO":    return .systemGreen
        case "DEBUG":   return .systemBlue
        case "ERROR":   return .systemRed
        case "TRACE":   return .systemGray
        case "FATAL":   return .systemPurple
        case "WARNING": return .systemOrange
        default:        return .black
        }
    }

    subscript(identifier: String) -> String {
        switch identifier {
        case "LINE_NUMBER": return "\(row)"
        case "TIME":        return time
        case "LEVEL":       return level
        case "THREAD":      return thread
        case "MESSAGE":     return message
        default:            return ""
        }
    }
}

extension LogLine: CustomStringConvertible {
    var description: String {
        return "[\(self.time)][\(self.level)][\(self.thread)]: \(self.message)"
    }
}

class LogViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!

    /// The cached log file data. Since we now the log size, we are sure that it always fits into the memory.
    private var cachedData: [LogLine] = []

    public var logData: Data? {
        return cachedData.map { $0.description }.joined(separator: "\n").data(using: .utf8)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the right click menu
        self.tableView.menu = self.createRightClickMenu()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.tableColumns.forEach { column in
            // column.minWidth = 10
            column.width = 10
            column.sortDescriptorPrototype = NSSortDescriptor(key: column.identifier.rawValue, ascending: true)
        }

        self.reloadData()
    }

    private func createRightClickMenu() -> NSMenu {
        let menu = NSMenu()
        let copyItem = NSMenuItem(title: "COPY_MENUITEM".localized, action: #selector(copyLines(sender:)),
                                  keyEquivalent: "c")
        copyItem.keyEquivalentModifierMask = .command
        menu.addItem(copyItem)
        return menu
    }

    @objc private func copyLines(sender: Any) {
        let indices = self.tableView.selectedRowIndexes
        let output = indices.map { self.cachedData[$0].description }.joined(separator: "\n")

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(output, forType: .string)
    }

    /// Sort the tableView data and update the UI.
    private func sortData() {
        defer {
            self.tableView.reloadData()
        }

        guard let descriptor = self.tableView.sortDescriptors.first else { return }

        let ascending = descriptor.ascending != true
        guard let key = descriptor.key else { return }

        self.cachedData.sort {
            if key == "LINE_NUMBER" {
                return ascending ? $0.row < $1.row : $0.row > $1.row
            }
            return ascending ? $0[key] < $1[key] : $0[key] > $1[key]
        }
    }

    /// Reload the data from the log file and update the UI.
    public func reloadData() {
        let fileManager = FileManager.default
        let logfile = fileManager.logfile

        if let data = fileManager.contents(atPath: logfile.path) {
            let stringData = String(data: data, encoding: .utf8)
            let lines = stringData?.components(separatedBy: CharacterSet.newlines) ?? []
            self.cachedData = lines.enumerated().compactMap { i, line in LogLine(row: i+1, line: line) }
        } else {
            self.cachedData = []
        }
        self.sortData()
    }
}

// MARK: - TableViewDataSource

extension LogViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.cachedData.count
    }
}

// MARK: - TableViewDelegate

extension LogViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier,
              let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        guard let identifier = tableColumn?.identifier.rawValue else { return nil }

        let logline = self.cachedData[row]
        cell.textField?.stringValue = logline[identifier]

        if identifier == "LEVEL" {
            cell.textField?.textColor = logline.levelColor
        }

        // Update the tableColumn width based on the required table width
        guard let column = tableColumn else { return cell }
        column.width = max(column.minWidth, min(max(cell.textFittingWidth, column.width), column.maxWidth))

        return cell
    }

    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        let rowRange = tableView.rows(in: tableView.visibleRect)
        let numberOfRows = tableView.numberOfRows

        let minRow = max(0, rowRange.location - 50)
        let maxRow = min(numberOfRows, rowRange.location + rowRange.length + 50)

        let tableColumn = tableView.tableColumns[column]
        let minWidth = tableColumn.minWidth
        let maxWidth = tableColumn.maxWidth
        var width = minWidth

        for row in minRow..<maxRow {
            if let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView {
                let fittingWidth: CGFloat = cell.textFittingWidth

                if fittingWidth > width {
                    width = fittingWidth

                    if width >= maxWidth {
                        break
                    }
                }
            }
        }
        return min(maxWidth, width+5)
    }

    func tableViewColumnDidResize(_ notification: Notification) {
        guard notification.object as? NSTableView == self.tableView else { return }
        self.tableView.sizeLastColumnToFit()
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        self.sortData()
    }
}
