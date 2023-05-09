//
//  Application.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import CoreLocation

extension Application {
    @objc(sinOf:) private func sinOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let num = params["of"] as? CGFloat else {
            command.setScriptASError(.InvalidArgument(expected: "of: real"))
            return nil
        }
        return sin(num)
    }

    @objc(cosOf:) private func cosOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let num = params["of"] as? CGFloat else {
            command.setScriptASError(.InvalidArgument(expected: "of: real"))
            return nil
        }
        return cos(num)
    }

    @objc(atanOf:) private func atanOf(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let y = params["y"] as? CGFloat,
                let x = params["x"] as? CGFloat else {
            command.setScriptASError(.InvalidArgument(expected: "y: real, x: real"))
            return nil
        }
        return atan2(y, x)
    }
}
