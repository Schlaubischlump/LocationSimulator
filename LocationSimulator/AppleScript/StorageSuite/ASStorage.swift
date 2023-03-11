//
//  ASStorage.swift
//  LocationSimulator
//
//  Created by David Klopp on 11.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

@objc(ASStorage) class ASStorage: NSObject {
    static var openStorages: [ASStorage] = []

    @objc let name: String

    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let appDescription = NSApp.classDescription as? NSScriptClassDescription else {
            return nil
        }
        return NSNameSpecifier(containerClassDescription: appDescription,
                               containerSpecifier: nil,
                               key: "storages", name: self.name)
    }

    private var data: [Int: Any] = [:]

    init(name: String) throws {
        self.name = name
        super.init()
        ASStorage.openStorages += [self]
    }

    @objc(storeData:) private func storeData(_ command: NSScriptCommand) -> Any? {
        print("Store the data...")
        guard let params = command.evaluatedArguments,
                let key = params["key"] as? Int,
                let value = params["value"] else {
            return false
        }
        let hasData = self.data[key] != nil
        self.data[key] = value
        return hasData
    }

    @objc(getData:) private func getData(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
              let key = params["key"] as? Int else {
            return nil
        }
        return self.data[key]
    }

    @objc(removeData:) private func removeData(_ command: NSScriptCommand) -> Any? {
        guard let params = command.evaluatedArguments,
              let key = params["key"] as? Int else {
            return false
        }
        return self.data.removeValue(forKey: key) != nil
    }

    @objc(close:) private func close(_ command: NSScriptCommand) {
        ASStorage.openStorages.removeAll { [weak self] in
            return $0.name == self?.name
        }
    }
}
