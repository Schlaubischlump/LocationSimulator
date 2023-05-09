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
    case InvalidArgument(expected: String)
    case InvalidCoordinate
    case InvalidCoordinateList
    case Timeout
}

extension ASError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingClassDescription:
            return NSLocalizedString("MissingClassDescription", comment: "MissingClassDescription")
        case .InvalidArgument(let expectedType):
            return NSLocalizedString("InvalidArgument: Expected `\(expectedType)`!", comment: "InvalidArgument")
        case .InvalidCoordinateList:
            return NSLocalizedString("InvalidCoordinateList: Expected `{{latitude: real, longitude: real}, ...}`!",
                                     comment: "InvalidCoordinateList")
        case .InvalidCoordinate:
            return NSLocalizedString("InvalidCoordinate: Expected `{latitude: real, longitude: real}`!",
                                     comment: "InvalidCoordinate")
        case .Timeout:
            return NSLocalizedString("Timeout: Operation timed out!", comment: "Timeout")
        }
    }
}

extension NSScriptCommand {
    func setScriptASError(_ error: ASError) {
        self.setScriptError(error as Error)
    }

    func setScriptError(_ error: Error) {
        self.scriptErrorNumber = (error as NSError).code
        self.scriptErrorString = error.localizedDescription
    }
}
