//
//  NSTableCellView+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 12.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import AppKit

extension NSTableCellView {
    public var textFittingWidth: CGFloat {
        return self.textField?.attributedStringValue.size().width ?? 0
    }
}
