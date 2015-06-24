//
//  DevicesFoundCollectionViewModel.swift
//  Savant
//
//  Created by Stephen Silber on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

protocol DevicesFoundViewDelegate {
    func deviceSelected(host: ConfigurableProvisionableDevice)
    func blinkLED(indexPath: NSIndexPath)
    func presentLightTypePicker(completion: (type: Int)->())
    func reloadData()
}

class DeviceModelItem: ModelItem {
    var deviceObject: ConfigurableProvisionableDevice?
}

class DevicesFoundCollectionViewModel: DataSource {
    var delegate: DevicesFoundViewDelegate?
    var hiddenDevices = [ModelItem]()
    
    required init(devices: [ConfigurableProvisionableDevice]) {
        super.init()
        setupDataSource(devices)
    }
    
    func setupDataSource(devices: [ConfigurableProvisionableDevice]) {
        var dataSource = [ModelItem]()
        for device in devices {
            if device.provisionableDevice?.savantDeviceType != .Host {
                let modelItem = DeviceModelItem()
                modelItem.deviceObject = device 
                dataSource.append(modelItem)
            }
        }

        setItems(dataSource)
        reloader?.reloadData()
    }
    
    func listenToDeleteButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = { [unowned self] in
            let modelItem = self.itemForIndexPath(indexPath)
            if let item = modelItem as? DeviceModelItem{
                self.hiddenDevices.append(item)
                if self.sections.count == 1 {
                    var currentItems = self.sections[0].items
                    if let index = find(currentItems, item) {
                        currentItems.removeAtIndex(index)
                        self.setItems(currentItems)
                        self.reloader?.reloadData()
                    }
                }
            }
        }
    }
    
    func listenToSelectRoomButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = { [unowned self] in
            let modelItem = self.itemForIndexPath(indexPath)
            self.selectItemAtIndexPath(indexPath, modelItem: modelItem!)
        }
    }

    func listenToLightTypeButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = {
            self.delegate?.presentLightTypePicker({ (type: Int) -> () in
                let modelItem = self.itemForIndexPath(indexPath)
                if let item = modelItem as? DeviceModelItem {
                    if type == 0 {
                        item.deviceObject?.lampModuleMode = ConfigurableDeviceLampModuleType.Dimmer
                    } else {
                        item.deviceObject?.lampModuleMode = ConfigurableDeviceLampModuleType.Switch
                    }
                    self.delegate?.reloadData()
                }
            })
        }
    }
    
    func listenToLinkButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = { [unowned self] in
            self.delegate?.blinkLED(indexPath)
        }
    }
    
    func updateDeviceName(name: String, indexPath: NSIndexPath) {
        let modelItem = self.itemForIndexPath(indexPath)
        if let item = modelItem as? DeviceModelItem {
            if let object = item.deviceObject {
                object.provisionableDevice?.name = name
            }
        }
    }
    
    func deviceNameForIndexPath(indexPath: NSIndexPath) -> String {
        var item = super.itemForIndexPath(indexPath) as! DeviceModelItem
        if let device = item.deviceObject {
            var name = ""
            
            if let n = device.provisionableDevice?.name {
                name = n
            }
            
            return name
        }
        
        return "Savant Device"
    }
    
    func deviceLightingTypeForIndexPath(indexPath: NSIndexPath) -> ConfigurableDeviceLampModuleType? {
        var item = super.itemForIndexPath(indexPath) as! DeviceModelItem
        var lightingType:ConfigurableDeviceLampModuleType? = nil

        if let device = item.deviceObject {
            if let t = device.lampModuleMode {
                lightingType = t
            }
        }
        
        return lightingType
    }
    
    func roomNameForIndexPath(indexPath: NSIndexPath) -> String {
        var item = super.itemForIndexPath(indexPath) as! DeviceModelItem
        var name = "Select Room"
        
        if let device = item.deviceObject {
            if let r = device.room {
                name = r.roomId
            }
        }
        
        return name
    }
    
    func uidForIndexPath(indexPath: NSIndexPath) -> String {
        if let item = itemForIndexPath(indexPath) as? DeviceModelItem {
            if let device = item.deviceObject, uid = device.provisionableDevice?.uid {
                return uid
            }
        }
        return ""
    }
    
    func devicesWithoutIgnored() -> [ConfigurableProvisionableDevice] {
        var arr = [ConfigurableProvisionableDevice]()
        
        if sections.count > 0 {
            let sectionOne = sections.first
            let sectionItems = sectionOne?.items
            
            if let items = sectionItems {
                for item in items {
                    if let i = item as? DeviceModelItem {
                        if let devObj = i.deviceObject {
                            arr.append(devObj)
                        }
                    }
                }
            }
        }
        
        return arr
    }

    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        var item = super.itemForIndexPath(indexPath) as! DeviceModelItem
        if let device = item.deviceObject {
            if device.provisionableDevice?.deviceType() == DeviceType.LampModule {
                item.type = 1
            }
            item.title = device.provisionableDevice?.name
        }
        
        return item
    }
    
    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        let modelItem = itemForIndexPath(indexPath) as! DeviceModelItem
        if let device = modelItem.deviceObject {
            delegate?.deviceSelected(device)
        }
    }
}
