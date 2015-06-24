//
//  DevicesDataModel.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class DevicesDataModel: DataSource {

    let coordinator: CoordinatorReference<InterfaceState>
    var roomFilter: SAVRoom?

    init(coordinator c: CoordinatorReference<InterfaceState>) {
        coordinator = c
        super.init()
    }

    func filterDevices(room: SAVRoom?) {
        roomFilter = room
    }

}
