//
//  DragAndDropBox.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

class DragAndDropBox: NSBox {

    /// The extensions for all allowed file types
    public var allowedTypes: [String] = []

    public var dropHandler: ((String) -> Void)?

    public var filePath: String? {
        didSet {
            guard let path = self.filePath, !path.isEmpty else { return }
            self.imageView.image = NSWorkspace.shared.icon(forFile: path)
        }
    }

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
        self.imageView.unregisterDraggedTypes()
        self.registerForDraggedTypes([.fileURL])
        self.addSubview(self.imageView)
    }

    override func layout() {
        super.layout()
        self.imageView.frame = self.bounds
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingSourceOperationMask.contains(.copy) {
            let pasteboard = sender.draggingPasteboard
            let files = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]

            if let files = files, files.count == 1 {
                return self.allowedTypes.contains(files[0].pathExtension) ? .copy : []
            }
        }
        return []
    }

    func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return .generic
    }

    func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        let files = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]
        if let files = files, files.count == 1, self.allowedTypes.contains(files[0].pathExtension) {
            let path = files[0].path
            self.filePath = path
            dropHandler?(path)
            return true
        }
        return false
    }
}
