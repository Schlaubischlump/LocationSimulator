//
//  XIBLocalizable.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.01.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

import Foundation
import AppKit

protocol XIBLocalizable {
    // Xcode does not support array IBInspectables. Therefore | is used as an array separator.
    var localeKey: String? { get set }
}

protocol PlaceholderXIBLocalizable {
    var localePlaceholderKey: String? { get set }
}

protocol TooltipXIBLocalizable {
    var localeToolTipKey: String? { get set }
}

protocol PaletteLabelXIBLocalizable {
    var localePaletteLabelKey: String? { get set }
}

// MARK: - NSView

extension NSView: TooltipXIBLocalizable {
    @IBInspectable var localeToolTipKey: String? {
        get { return nil }
        set(key) { self.toolTip = key?.localized }
    }
}

// MARK: - NSToolbarItem

extension NSToolbarItem: TooltipXIBLocalizable, PaletteLabelXIBLocalizable {
    @IBInspectable var localePaletteLabelKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.paletteLabel = localized
            }
        }
    }

    @IBInspectable var localeToolTipKey: String? {
        get { return nil }
        set(key) { self.toolTip = key?.localized }
    }
}

// MARK: - NSMENU

extension NSMenu: XIBLocalizable {
    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.title = localized
            }
        }
    }
}

extension NSMenuItem: XIBLocalizable {
    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.title = localized
            }
        }
    }
}

// MARK: - NSSegementedControl

extension NSSegmentedControl: XIBLocalizable {
    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            // The localization key for a segmented control should have the format:
            // key1|key2|key3
            let keys = key?.components(separatedBy: "|")
            keys?.enumerated().forEach { (i, k) in
                self.setLabel(k.localized, forSegment: i)
            }
        }
    }
}

// MARK: - NSButton

extension NSButton: XIBLocalizable {
    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.title = localized
            }
        }
    }
}

// MARK: - NSTextField

extension NSTextFieldCell: PlaceholderXIBLocalizable {
    @IBInspectable var localePlaceholderKey: String? {
        get { return nil }
        set(key) {
            self.placeholderString = key?.localized
        }
    }
}

extension NSTextField: PlaceholderXIBLocalizable, XIBLocalizable {
    @IBInspectable var localePlaceholderKey: String? {
        get { return (self.cell as? NSTextFieldCell)?.localePlaceholderKey }
        set(key) {
            (self.cell as? NSTextFieldCell)?.localePlaceholderKey = key
        }
    }

    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.stringValue = localized
            }
        }
    }
}

// MARK: - NSViewController

extension NSViewController: XIBLocalizable {
    @IBInspectable var localeKey: String? {
        get { return nil }
        set(key) {
            if let localized = key?.localized, key != localized {
                self.title = localized
            }
        }
    }
}
