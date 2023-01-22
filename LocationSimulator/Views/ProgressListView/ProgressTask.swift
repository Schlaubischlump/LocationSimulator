//
//  ProgressTask.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

protocol ProgressTask: AnyObject {
    // You must update this value from the outside
    var progress: Float { get }
    var showSpinner: Bool { get }
    var showProgress: Bool { get }

    // You must not set these values, but you should call these methods
    var onProgress: ((Float) -> Void)? { get set }
    var onCompletion: ((Float) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    // You should override this method
    func description(forProgress: Float) -> String
}
