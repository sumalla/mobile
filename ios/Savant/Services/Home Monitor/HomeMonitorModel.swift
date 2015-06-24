//
//  HomeMonitorModel.swift
//  Savant
//
//  Created by Joseph Ross on 3/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

protocol HomeMonitorModelDelegate: class {
    func reloadData()
    func reloadIndexPath(indexPath:NSIndexPath)
    func selectedMonitor(monitor:HomeMonitor)
}

class HomeMonitorModel: DataSource {
    var service:SAVService!
    var objects:[HomeMonitor]?
    weak var delegate:HomeMonitorModelDelegate?
    
    
    init(service:SAVService) {
        super.init()
        
        self.service = service
        loadDataIfNecessary()
    }
    
    func cellTypeForIndexPath(indexPath: NSIndexPath!) -> UInt {
        return 0
    }
    
    func loadDataIfNecessary() {
        if objects == nil {
            loadHomeMonitorData()
            delegate?.reloadData()
        }
    }
    
    func loadHomeMonitorData() {
        let allMonitors = HomeMonitor.monitorsForService(service)
        objects = allMonitors
        var rowIndex = 0;
        var items:[ModelItem] = map(allMonitors) { (monitor) -> ModelItem in
            let modelItem = ModelItem()
            let indexPath = NSIndexPath(forRow: rowIndex++, inSection: 0)
            modelItem.title = monitor.name
            modelItem.subtitle = monitor.zoneName
            modelItem.dataObject = monitor
            modelItem.image = monitor.snapshot
            return modelItem
        }
        setItems(items)
    }
    
    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: ModelItem) {
        let monitor = modelItem.dataObject as! HomeMonitor
        self.delegate?.selectedMonitor(monitor)
        
    }
}
