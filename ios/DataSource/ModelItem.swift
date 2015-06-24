//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public class ModelItem: NSObject, NSCopying {

    public var dataObject: AnyObject?
    public var title: String?
    public var subtitle: String?
    public var type: Int = 0
    public var image: UIImage?

    public required override init() {
        super.init()
    }

    public func copyWithZone(zone: NSZone) -> AnyObject {
        let mi = self.dynamicType()
        mi.dataObject = dataObject
        mi.title = title
        mi.subtitle = subtitle
        mi.type = type
        return mi
    }

}
