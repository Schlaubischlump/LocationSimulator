//
//  AutoCompleteTextField.swift
//  AutoCompleteTextFieldDemo
//
//  Created by fancymax on 15/12/12.
//  Modified by David Klopp on 11/08/19.
//  Copyright © 2015年 fancy. All rights reserved.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// Based on: https://github.com/fancymax/AutoCompleteTextField

import AppKit

struct Match {
    var text: String = ""
    var detail: String = ""
    var data: Any?
}

class AutoCompleteSearchField: NSSearchField {
    @IBInspectable var popOverWidth: CGFloat = 100.0

    weak var tableViewDelegate: AutoCompleteTableViewDelegate?

    let popOverPadding: CGFloat = 0.0

    let maxResults = 10

    var matches: [Match]?

    private var localKeyEventMonitor: Any?

    public var autoCompletePopover: AutoCompletePopover?

    public var autoCompleteTableView: NSTableView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    override func becomeFirstResponder() -> Bool {
        // Show popover if we click inside of the textField or enter the focus.
        if !self.stringValue.isEmpty {
            self.showMatches(self.matches ?? [])
        }
        return super.becomeFirstResponder()
    }

    func setup() {
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "text"))
        column1.isEditable = false
        column1.width = popOverWidth - 2 * self.popOverPadding

        let tableView = NSTableView(frame: .zero)
        tableView.selectionHighlightStyle = NSTableView.SelectionHighlightStyle.regular
        tableView.backgroundColor = .clear
        tableView.rowSizeStyle = NSTableView.RowSizeStyle.custom
        tableView.rowHeight = 36.0
        tableView.intercellSpacing = NSSize(width: 5.0, height: 0.0)
        tableView.headerView = nil
        tableView.refusesFirstResponder = true
        tableView.target = self
        tableView.action = #selector(insert(_:))
        tableView.addTableColumn(column1)
        if #available(OSX 11.0, *) {
            tableView.style = .fullWidth
        }
        tableView.delegate = self
        tableView.dataSource = self
        self.autoCompleteTableView = tableView

        let tableScrollView = NSScrollView(frame: .zero)
        tableScrollView.drawsBackground = false
        tableScrollView.documentView = tableView
        tableScrollView.hasVerticalScroller = true
        tableScrollView.hasHorizontalScroller = false
        tableScrollView.automaticallyAdjustsContentInsets = false
        tableScrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let contentView = NSView(frame: NSRect.init(x: 0, y: 0, width: popOverWidth, height: 0))
        contentView.addSubview(tableScrollView)

        let contentViewController = NSViewController()
        contentViewController.view = contentView

        self.autoCompletePopover = AutoCompletePopover(contentViewController: contentViewController)

        // if the textfield is a searchfield and has a clear button apply a function to update the suggestions
        if let cell = self.cell as? NSSearchFieldCell {
            cell.cancelButtonCell?.target = self
            cell.cancelButtonCell?.action = #selector(clearText(_:))
        }

        self.matches = []

        self.localKeyEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp]) { [unowned self] (event) -> NSEvent? in
            // if this textfield is the first responder
            if self.window?.firstResponder == self.currentEditor() {
                return self.processSpecialKeys(with: event)
            }
            return event
        }
    }

    deinit {
        if let eventMonitor = self.localKeyEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.localKeyEventMonitor = nil
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func processSpecialKeys(with theEvent: NSEvent) -> NSEvent? {
        let keyUp: Bool = theEvent.type == .keyUp

        guard let row: Int = self.autoCompleteTableView?.selectedRow,
            let isShow = self.autoCompletePopover?.isVisible else {
                return theEvent
        }

        // do some magic on keyDown
        switch theEvent.keyCode {

        case 125: // Arrow Down
            if isShow && !keyUp {
                self.autoCompleteTableView?.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
                self.autoCompleteTableView?.scrollRowToVisible((self.autoCompleteTableView?.selectedRow)!)
            }
            return nil
        case 126: // Arrow Up
            if isShow && !keyUp {
                self.autoCompleteTableView?.selectRowIndexes(IndexSet(integer: row - 1), byExtendingSelection: false)
                self.autoCompleteTableView?.scrollRowToVisible((self.autoCompleteTableView?.selectedRow)!)
            }
            return nil
        case 36: // Return
            if isShow && !keyUp {
                self.insert(self)
            }
            return nil
        case 48: // Tab
            if isShow {
                self.autoCompletePopover?.hide()
            }
        default:
            break
        }

        if keyUp {
            self.tableViewDelegate?.textField(self, textDidChange: self.stringValue)
        }

        return theEvent
    }
    // swiftlint:enable cyclomatic_complexity

    @objc func clearText(_ sender: AnyObject) {
        self.stringValue = ""
        self.showMatches([])
        self.tableViewDelegate?.textField(self, textDidChange: "")
    }

    @objc func insert(_ sender: AnyObject) {
        let selectedRow = self.autoCompleteTableView!.selectedRow
        let matchCount = self.matches!.count
        if selectedRow >= 0 && selectedRow < matchCount {
            let match = self.matches![selectedRow]
            self.stringValue = match.text
            self.tableViewDelegate!.textField(self, didSelectItem: match)
        }
        self.autoCompletePopover?.hide()
    }

    func showMatches(_ matches: [Match]) {
        // Save the last matches.
        self.matches = matches

        let lengthOfWord = self.stringValue.count
        let subStringRange = NSRange(location: 0, length: lengthOfWord)

        // This happens when we just started a new word or if we have already typed the entire word.
        if subStringRange.length == 0 || lengthOfWord == 0 {
            self.autoCompletePopover?.hide()
            return
        }

        let index = 0

        if self.matches!.count > 0 {
            self.autoCompleteTableView?.reloadData()
            self.autoCompleteTableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            self.autoCompleteTableView?.scrollRowToVisible(index)
            self.updatePopoverContentSize()

            if !(self.autoCompletePopover?.isVisible ?? true) {
                self.autoCompletePopover?.show(relativeTo: self.bounds, of: self)
            }
        } else {
            self.autoCompletePopover?.hide()
        }
    }

    func updatePopoverContentSize() {
        let numberOfRows = min(self.autoCompleteTableView.numberOfRows, maxResults)
        let rowHeight = self.autoCompleteTableView.rowHeight
        let spacing = self.autoCompleteTableView.intercellSpacing
        let height = (rowHeight + spacing.height) * CGFloat(numberOfRows)
        let frame = NSRect(x: 0, y: 0, width: popOverWidth + spacing.width, height: height)
        self.autoCompleteTableView.enclosingScrollView?.frame = frame.insetBy(dx: self.popOverPadding, dy: 0)
        self.autoCompletePopover?.setContentSize(frame.size)
    }
}
