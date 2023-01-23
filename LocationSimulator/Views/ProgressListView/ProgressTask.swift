//
//  ProgressTask.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

@objc protocol ProgressTask: NSObjectProtocol {
    // You must update this value from the outside
    @objc dynamic var progress: Double { get set }
    var showSpinner: Bool { get }
    var showProgress: Bool { get }

    // You should override this method
    func description(forProgress: Double) -> String
}
