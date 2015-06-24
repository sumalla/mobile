//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public class Section {

    public var headerTitle = ""
    public var footerTitle = ""
    public var items = [ModelItem]()
    public var type: Int = 0

    public var count: Int {
        return items.count
    }

    public init() {
        
    }

    public init(modelItems: [ModelItem]) {
        items = modelItems
    }

}
