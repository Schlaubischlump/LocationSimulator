//
//  DragAndDropBox.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

/// A NSBox subclass that allows dropping files to it. Only files with the extension specified in `allowedTypes` are
/// supported. A preview image of the file icon will be displayed if a file is dropped.
class DragAndDropBox: NSBox {

    /// The extensions for all allowed file types
    public var allowedTypes: [String] = []

    /// Callback handler when a new file is dropped
    public var dropHandler: ((String) -> Void)?

    /// The file path of the currently received file, or nil if none is available
    public var filePath: String? {
        didSet {
            guard let path = self.filePath, !path.isEmpty else { return }
            self.imageView.image = NSWorkspace.shared.icon(forFile: path)
        }
    }

    /// Internal image view property for the file icon.
    private let imageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        // Disable the native imageView drop functionality
        self.imageView.unregisterDraggedTypes()
        // Allow dragging files
        self.registerForDraggedTypes([.fileURL])

        // Add the imageView
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.imageView)

        let constraints = [
            self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
            self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            self.imageView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -14),
            self.imageView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -14)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func highlightDropArea(_ highlight: Bool) {
        self.imageView.layer?.cornerRadius = 5.0
        self.imageView.layer?.backgroundColor = highlight ? NSColor.black.withAlphaComponent(0.2).cgColor : .clear
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Display a copy (+) icon when exactly one file with a matching extension is dropped
        if sender.draggingSourceOperationMask.contains(.copy) {
            let pasteboard = sender.draggingPasteboard
            let files = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]

            if let files = files, files.count == 1, self.allowedTypes.contains(files[0].pathExtension) {
                self.highlightDropArea(true)
                return .copy
            }
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.highlightDropArea(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.highlightDropArea(false)

        // Call the callback handler and update the file if the drop ended
        let pasteboard = sender.draggingPasteboard
        let files = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]
        if let files = files, files.count == 1, self.allowedTypes.contains(files[0].pathExtension) {
            let path = files[0].path
            self.filePath = path
            self.dropHandler?(path)
            return true
        }
        return false
    }
}
