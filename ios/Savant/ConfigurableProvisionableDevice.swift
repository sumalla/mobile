//
//  ConfigurableProvisionableDevice.swift
//  Savant
//
//  Created by Julian Locke on 5/28/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ConfigurableProvisionableDevice: ConfigurableDevice {
    init(aProvisionableDevice: ProvisionableDevice) {
        super.init()
        provisionableDevice = aProvisionableDevice
        deviceType = .Bluetooth
    }
}

func ==(lhs: ConfigurableProvisionableDevice, rhs: ConfigurableProvisionableDevice) -> Bool {
    return ((lhs.provisionableDevice?.uid == rhs.provisionableDevice?.uid) && lhs.provisionableDevice?.uid != nil && rhs.provisionableDevice?.uid != nil)
}