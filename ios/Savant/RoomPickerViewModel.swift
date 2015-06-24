//
//  PickRoomDataModel.swift
//  Savant
//
//  Created by Alicia Tams on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

enum PickRoomCellType: Int {
	case Add = 0
	case Switch = 1
}

class PickRoomViewModel: DataSource {
	
	private var modelItems = [ModelItem]()
	
	override init() {
		super.init()
		
		let addNewRoom = ModelItem()
		addNewRoom.type = PickRoomCellType.Add.rawValue
		addNewRoom.title = Strings.addRoom
		modelItems.append(addNewRoom)
		
		for room in Savant.data().allRooms() as! [SAVRoom] {
			let item = ModelItem()
			
			item.title = room.roomId
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