//
//  Util.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public func groupBy<KeyType, ItemType>(items: [ItemType], block: (item: ItemType) -> KeyType) -> [KeyType: [ItemType]] {
    var groupedItems = [KeyType: [ItemType]]()

    for item in items {
        let key = block(item: item)

        var array: [ItemType]!

        if let a = groupedItems[key] {
            array = a
        } else {
            array = [ItemType]()
        }

        array.append(item)
        groupedItems[key] = array
    }

    return groupedItems
}
