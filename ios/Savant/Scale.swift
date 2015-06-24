//
//  Scale.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

let Scale = ScaleManager()

class ScaleManager: NSObject {

    let baseValue: CGFloat

    private override init() {
        if UIDevice.isShortPhone() {
            baseValue = 8
        } else {
            baseValue = 10
        }
    }

}
