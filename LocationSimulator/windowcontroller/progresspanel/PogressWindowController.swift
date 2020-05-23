//
//  PogressWindowController.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class ProgressWindowController: NSWindowController {

    /**
     - Return: new instance of this class from the storyboard
     */
    class func newInstance() -> ProgressWindowController {
        let mainStoryboard = NSStoryboard.init(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateController(withIdentifier: "progressWindowController")
        return (viewController as? ProgressWindowController)!
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
