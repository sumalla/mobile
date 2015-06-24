//
//  HostsFoundCollectionViewModel.swift
//  Savant
//
//  Created by Stephen Silber on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import DataSource
import Coordinator

protocol HostsFoundViewDelegate {
    func hostSelected(host: ProvisionableDevice)
}

class HostModelItem: ModelItem {
    var hostUID: String?
    var hostObject: ProvisionableDevice?
}

class HostsFoundCollectionViewModel: DataSource {
    var delegate: HostsFoundViewDelegate?
    
    required init(hosts: [ProvisionableDevice]) {
        super.init()
        setupDataSource(hosts)
    }
    
    func setupDataSource(hosts: [ProvisionableDevice]) {
        var dataSource = [ModelItem]()
        for device in hosts {
            if device.savantDeviceType == .Host {
                let modelItem = HostModelItem()
                modelItem.hostObject = device
                modelItem.hostUID = device.uid
                dataSource.append(modelItem)
            }
        }
        
//        if count(hosts) == 1 {
//            delegate?.hostSelected(hosts[0])
//        } else {
        setItems(dataSource)
        reloader?.reloadData()
//        }
    }
    
    func listenToSelectHostButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = { [unowned self] in
            let modelItem = self.itemForIndexPath(indexPath)
            self.selectItemAtIndexPath(indexPath, modelItem: modelItem!)
        }
    }
    
    func listenToLinkButton(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = {
            println("Link button pressed")
        }
    }
    
    func homeNameForIndexPath(indexPath: NSIndexPath) -> String {
        return "Savant Host"
    }
    
    func uidForIndexPath(indexPath: NSIndexPath) -> String {
        let item = itemForIndexPath(indexPath) as! HostModelItem
        return item.hostUID!
    }

    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        var item = super.itemForIndexPath(indexPath) as! HostModelItem
        item.title = "Savant Host"
        
        return item
    }
    
    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        let modelItem = itemForIndexPath(indexPath) as! HostModelItem
        if let host = modelItem.hostObject {
            delegate?.hostSelected(host)
        }
    }
}
