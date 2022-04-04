//
//  Constants.swift
//  LocationSimulator
//
//  Created by David Klopp on 23.03.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation

// let kAppName = Bundle.main.infoDictionary?["CFBundleName"] as? String
// let kAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
// let kAppVersionTag = kAppVersion != nil ? "v\(kAppVersion!)" : nil

let kUser = "Schlaubischlump"
let kRepo = "LocationSimulator"

let kProjectWebsite = "https://\(kUser.lowercased()).github.io/\(kRepo)/"
let kGithubWebsite = "https://github.com/\(kUser)/\(kRepo)"
// let kGithubStatsWebsite = "https://api.github.com/ repos/\(kUser)/\(kRepo)/releases"

// The variance to add to the movement speed. The lower bound is the minimum factor, the upper bounds the maximum
// factor to apply to the current speed. See LocationSpoofer for more details.
let kDefaultMovementSpeedVariance = 0.8..<1.2
