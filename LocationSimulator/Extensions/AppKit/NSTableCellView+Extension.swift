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
        guard let font = self.textField?.font, let text = self.textField?.stringValue else { return 0 }

        let fontAttributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: fontAttributes).width
    }
}
