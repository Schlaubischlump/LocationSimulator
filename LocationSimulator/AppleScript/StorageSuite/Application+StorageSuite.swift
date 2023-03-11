//
//  Application+StorageSuite.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension Application {
    @objc(openStorage:) private func openStorage(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let name = params["name"] as? String else {
            return false
        }
        do {
            if let storage = ASStorage.openStorages.first(where: { $0.name == name }) {
                return storage
            } else {
                return try ASStorage(name: name)
            }
        } catch let error {
            command.scriptErrorNumber = (error as NSError).code
            command.scriptErrorString = error.localizedDescription
        }
        return nil
    }
}
