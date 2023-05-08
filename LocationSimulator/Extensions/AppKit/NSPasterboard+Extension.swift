//
//  NSPasterboard+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 17.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSPasteboard {
    /**
     Read the first pasteboard item and try to parse it as location coordinates.
     - Return: Coordinates as (Double, Double) of first pasteboard item if avaiable.
     */
    func parseFirstItemAsCoordinates() -> (Double, Double)? {
        // Read the first pasteboard item as string
        guard let pasteboardItem = self.pasteboardItems?.first?.string(forType: .string) else {
            return nil
        }

        // Try to split the component in lat and long.
        let strippedString = pasteboardItem.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = strippedString.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        if components.count == 2 {
            // Trim the whitespace and interpret the coordinates as location coordinates
            let first = String(components.first!).trimmingCharacters(in: .whitespaces)
            let second = String(components.last!).trimmingCharacters(in: .whitespaces)
            if let lat = Double(first), let long = Double(second) {
                return (lat, long)
            }
        }

        return nil
    }
}
