//
//  NSViewController+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 24.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

extension NSViewController {
    public var enclosingSplitViewController: NSSplitViewController? {
        // Go up the viewController hierachy until a NSSplitViewController is found and return it.
        var currentVC: NSViewController? = self
        repeat {
            if let splitViewController = currentVC as? NSSplitViewController {
                return splitViewController
            }
            currentVC = currentVC?.parent
        } while (currentVC != nil)
        return nil
    }
}
