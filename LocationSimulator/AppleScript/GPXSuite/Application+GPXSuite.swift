//
//  Application+DeviceSuite.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension Application {
    @objc(loadGPXFile:) private func loadGPXFile(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
                let gpxFileURL = params["file"] as? URL else {
            return false
        }
        // Load and parse the input file.
        do {
            return try ASGPXFile(file: gpxFileURL)
        } catch let error {
            command.scriptErrorNumber = (error as NSError).code
            command.scriptErrorString = error.localizedDescription
        }
        return nil
    }
}
