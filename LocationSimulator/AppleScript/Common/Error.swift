//
//  Error.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

enum ASError: Error {
    case MissingClassDescription
    case InvalidCoordinate
    case Timeout
}

extension ASError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingClassDescription:
            return NSLocalizedString("MissingClassDescription", comment: "MissingClassDescription")
        case .InvalidCoordinate:
            return NSLocalizedString("InvalidCoordinate: Expected {lat, lon}!", comment: "InvalidCoordinate")
        case .Timeout:
            return NSLocalizedString("Timeout: Operation timed out!", comment: "Timeout")
        }
    }
}
