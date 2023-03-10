//
//  ASIndexedContainerItem.swift
//  LocationSimulator
//
//  Created by David Klopp on 10.03.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation

/// A base class for an apple script object inside a container with a fixed index in a collection.
class IndexedContainerItem: NSObject {
    private let container: NSScriptObjectSpecifier?
    private let index: Int
    private let key: String

    init(key: String, atIndex: Int, inContainer: NSScriptObjectSpecifier?) {
        self.key = key
        self.container = inContainer
        self.index = atIndex
        super.init()
    }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let containerDescription = self.container?.keyClassDescription as? NSScriptClassDescription else {
            return nil
        }
        return NSIndexSpecifier(containerClassDescription: containerDescription,
                                containerSpecifier: self.container,
                                key: self.key,
                                index: self.index)
    }
}
