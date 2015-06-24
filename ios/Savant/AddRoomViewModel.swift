//
//  AddRoomViewModel.swift
//  Savant
//
//  Created by Julian Locke on 5/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//


import UIKit
import DataSource

enum AddRoomCellType: Int {
    case Add = 0
    case Switch = 1
}
    
class AddRoomViewModel: DataSource {
    private var modelItems = [ModelItem]()
    
    override init() {
        super.init()
        
        let roomTypes = ["Bedroom","Bathroom","Kitchen","Living Room","Patio","Office","Studio","Den","Entry","Hallway"]
        var rooms: [SAVRoom] = []
        
        for roomType in roomTypes {
            var room = SAVRoom()
            room.roomType = roomType
            rooms.append(room)
        }
        
        for room in rooms {
            let item = ModelItem()
            
            item.title = room.roomType
            item.type = PickRoomCellType.Switch.rawValue
            item.dataObject = room
            
            modelItems.append(item)
        }
        setItems(modelItems)
    }
    
    override func numberOfSections() -> Int {
        return 1
    }
    
    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        return modelItems[indexPath.row]
    }
}