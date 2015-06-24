//
//  ConfigurableProvisionableDevice.swift
//  Savant
//
//  Created by Julian Locke on 5/28/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

@objc public enum ConfigurableDeviceLampModuleType : Int32 {
    case Switch       = 0
    case Dimmer       = 1
    case LightSwitch  = 2
}

@objc public enum ConfigurableDeviceType : Int32 {
    case Bluetooth    = 0
    case Sonos        = 1
//    case etc          = 2
}

class ConfigurableDevice: NSObject {
    internal var uid:String?
    internal var deviceType:ConfigurableDeviceType?
    internal var deviceName:String?
    internal var provisionableDevice:ProvisionableDevice?
    internal var room:SAVRoom?
    internal var lampModuleMode:ConfigurableDeviceLampModuleType?
}
