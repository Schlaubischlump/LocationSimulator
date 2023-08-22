//
//  URL+Extension.swift
//  LocationSimulator
//
//  Created by David Klopp on 22.08.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

extension URL {
    func appendPaths(paths: [String]) -> URL {
        return paths.reduce(self) { (result, dir) in result.appendingPathComponent(dir) }
    }
}
