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
    var data: Any? = nil
}


class AutoCompleteTextField: NSTextField {
    @IBInspectable var popOverWidth: CGFloat = 100.0
    
    weak var tableViewDelegate: AutoCompleteTableViewDelegate?

    let popOverPadding: CGFloat = 0.0

    let maxResults = 10

    var matches: [Match]?

    private var localKeyEventMonitor: Any?

    public var autoCompletePopover: AutoCompletePopover?

    public var autoCompleteTableView: NSTableView?


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
            self.complete(self)
        }
        return super.becomeFirstResponder()
    }

    func setup() {
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "text"))
        column1.isEditable = false
        column1.width = popOverWidth - 2 * popOverPadding

        let tableView = NSTableView(frame: NSZeroRect)
        tableView.selectionHighlightStyle = NSTableView.SelectionHighlightStyle.regular
        tableView.backgroundColor = NSColor.clear
        tableView.rowSizeStyle = NSTableView.RowSizeStyle.custom
        tableView.rowHeight = 36.0
        tableView.intercellSpacing = NSMakeSize(5.0, 0.0)
        tableView.headerView = nil
        tableView.refusesFirstResponder = true
        tableView.target = self
        tableView.action = #selector(insert(_:))
        tableView.addTableColumn(column1)
        tableView.delegate = self
        tableView.dataSource = self
        self.autoCompleteTableView = tableView

        let tableSrollView = NSScrollView(frame: NSZeroRect)
        tableSrollView.drawsBackground = false
        tableSrollView.documentView = tableView
        tableSrollView.hasVerticalScroller = true
        tableSrollView.hasHorizontalScroller = false

        let contentView = NSView(frame: NSRect.init(x: 0, y: 0, width: popOverWidth, height: 0))
        contentView.addSubview(tableSrollView)

        let contentViewController = NSViewController()
        contentViewController.view = contentView

        self.autoCompletePopover = AutoCompletePopover(contentViewController: contentViewController)

        // if the textfield is a searchfield and has a clear button apply a function to update the suggestions
        if let cell = self.cell as! NSSearchFieldCell? {
            cell.cancelButtonCell?.target = self
            cell.cancelButtonCell?.action = #selector(clearText(_:))
        }

        self.matches = []

        self.localKeyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp])
        { [unowned self] (event) -> NSEvent? in
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

    func processSpecialKeys(with theEvent: NSEvent) -> NSEvent? {
        let keyUp: Bool = theEvent.type == .keyUp

        guard let row: Int = self.autoCompleteTableView?.selectedRow,
            let isShow = self.autoCompletePopover?.isVisible else {
                return theEvent
        }

        // do some magic on keyDown
        switch(theEvent.keyCode){

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
        /*case 49: //Space
            if isShow && !keyUp {
                self.insert(self)
            }
            return nil*/
        default:
            break
        }

        if keyUp {
            self.complete(self)
        }

        return theEvent
    }

    @objc func clearText(_ sender: AnyObject) {
        self.stringValue = ""
        self.complete(sender)
    }

    @objc func insert(_ sender: AnyObject){
        let selectedRow = self.autoCompleteTableView!.selectedRow
        let matchCount = self.matches!.count
        if selectedRow >= 0 && selectedRow < matchCount {
            let match = self.matches![selectedRow]
            self.stringValue = match.text
            self.tableViewDelegate!.textField(self, didSelectItem: match)
        }
        self.autoCompletePopover?.hide()
    }
    
    @objc override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        let subStringRange = NSMakeRange(0, lengthOfWord)
        
        //This happens when we just started a new word or if we have already typed the entire word
        if subStringRange.length == 0 || lengthOfWord == 0 {
            self.autoCompletePopover?.hide()
            return
        }
        
        let index = 0
        self.matches = self.completionsForPartialWordRange(subStringRange, indexOfSelectedItem: index)

        if self.matches!.count > 0 {
            self.autoCompleteTableView?.reloadData()
            self.autoCompleteTableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            self.autoCompleteTableView?.scrollRowToVisible(index)
            self.updatePopoverContentSize()

            if !self.autoCompletePopover!.isVisible {
                self.autoCompletePopover?.show(relativeTo: self.bounds, of: self)
            }
        }
        else{
            self.autoCompletePopover?.hide()
        }
    }

    func completionsForPartialWordRange(_ charRange: NSRange, indexOfSelectedItem index: Int) ->[Match]{
        return self.tableViewDelegate!.textField(self, completions: [], forPartialWordRange: charRange, indexOfSelectedItem: index)
    }

    func updatePopoverContentSize() {
        let numberOfRows = min(self.autoCompleteTableView!.numberOfRows, maxResults)
        let height = (self.autoCompleteTableView!.rowHeight + self.autoCompleteTableView!.intercellSpacing.height) * CGFloat(numberOfRows) + 2 * 0.0
        let frame = NSMakeRect(0, 0, popOverWidth + self.autoCompleteTableView!.intercellSpacing.width, height)
        self.autoCompleteTableView?.enclosingScrollView?.frame = NSInsetRect(frame, popOverPadding, popOverPadding)
        self.autoCompletePopover?.setContentSize(NSMakeSize(NSWidth(frame), NSHeight(frame)))
    }
}

