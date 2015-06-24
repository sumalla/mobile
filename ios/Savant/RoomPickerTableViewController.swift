//
//  PickRoomTableViewController.swift
//  Savant
//
//  Created by Alicia Tams on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class RoomPickerTableViewController: ModelTableViewController {
	
	unowned var containingRoomPicker:RoomPickerViewController

	let datasource = PickRoomViewModel()
	
	init(containingRoomPicker c:RoomPickerViewController) {
		containingRoomPicker = c
		super.init(nibName: nil, bundle: nil)
	}
	
	required init!(coder aDecoder: NSCoder!) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDataSource() -> DataSource {
		return datasource
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, 200, Sizes.row * 11))
		tableView.allowsMultipleSelection = false
		tableView.backgroundColor = UIColor.clearColor()
		
		var label = UILabel(frame: CGRectZero)
		label.font = Fonts.body
		label.textColor = Colors.color1shade1
		label.text = "Rooms"
		
		tableView.tableHeaderView?.addSubview(label)
		tableView.tableHeaderView?.sav_pinView(label, withOptions: .ToBottom, withSpace: 20)
		tableView.tableHeaderView?.sav_pinView(label, withOptions: .CenterX)
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 60
	}
	
	override func registerCells() {
		registerCell(type: PickRoomCellType.Switch.rawValue, cellClass: PickRoomCellSwitch.self)
		registerCell(type: PickRoomCellType.Add.rawValue, cellClass: PickRoomCellAdd.self)
	}
	
	override func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
		cell.backgroundColor = UIColor.clearColor()
		cell.textLabel?.textColor = Colors.color1shade1
		
		let item = datasource.itemForIndexPath(indexPath)
		if let room = item?.dataObject as? SAVRoom, cell = cell as? PickRoomCellSwitch	{
			if (containingRoomPicker.selectedRoom == room) {
				cell.switchView.setOn(true, animated: false)
			}
		}
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {		
		if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PickRoomCellSwitch {
			
			let modelItem = datasource.itemForIndexPath(indexPath)
			
			for cell in tableView.visibleCells() as! [PickRoomCell] {
				if let switchCell = cell as? PickRoomCellSwitch {
					if (switchCell.switchView.on) {
						switchCell.switchView.setOn(false, animated: true)
					}
				}
			}
			
			if modelItem?.dataObject as? SAVRoom != containingRoomPicker.selectedRoom {
				cell.switchView.setOn(true, animated: true)
				containingRoomPicker.selectedRoom = modelItem?.dataObject as? SAVRoom
			}
			else {
				cell.switchView.setOn(false, animated: true)
				containingRoomPicker.selectedRoom = nil
			}			
		}
		
		if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PickRoomCellAdd {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			containingRoomPicker.addRoomTapped()
        }
	}
}
