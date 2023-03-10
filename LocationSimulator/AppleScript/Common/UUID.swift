//
//  ID.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

private var uuidCache: [AnyHashable: String] = [:]

func newUniqueId(key: AnyHashable) -> String {
    if let id = uuidCache[key] {
        return id
    }
    let id = UUID().uuidString
    uuidCache[key] = id
    return id
}
