//
//  PickRoomViewController.swift
//  Savant
//
//  Created by Alicia Tams on 5/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

protocol RoomPickerDelegate:NSObjectProtocol {
    func roomPicker(roomPicker:RoomPickerViewController, selectedRoom room: SAVRoom?)
	func roomPickerCanceledSelection(roomPicker: RoomPickerViewController)
}

enum RoomPickerViewControllerBackground {
	case Host
	case LightingModule
	case Camera
	case Switch
	case Default
}


class RoomPickerBaseViewController: ViewController {
	
	let backgroundImage:UIImage
	var imageView = UIImageView()
	
	init(background: RoomPickerViewControllerBackground = .Default) {
		
		switch (background) {
		case (.Host):
			fallthrough
		case (.LightingModule):
			fallthrough
		case (.Camera):
			fallthrough
		case (.Switch):
			fallthrough
		case (.Default):
			fallthrough
		default:
			backgroundImage = UIImage(named: "whole-home.jpg")!
		}
		
		super.init(nibName: nil, bundle: nil)
	}

	override func viewDidLoad() {
		imageView.image = backgroundImage
		self.view.insertSubview(imageView, atIndex: 0)
		
		view.sav_addFlushConstraintsForView(imageView)
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
}

class RoomPickerViewController: RoomPickerBaseViewController {
	weak var device:ConfigurableProvisionableDevice?
    weak var delegate:RoomPickerDelegate?

	var selectedRoom:SAVRoom? {
		didSet {
			if let selectedRoom = selectedRoom {
				doneButton.title = Strings.done
			} else {
				doneButton.title = Strings.cancel
			}
		}
	}
	var tableViewController:RoomPickerTableViewController?
	
	let doneButton = SCUButton(style: .PinnedButton)
	
	init(delegate d:RoomPickerDelegate?, selectedRoom:SAVRoom? = nil, background:RoomPickerViewControllerBackground = .Default) {
		
		self.selectedRoom = selectedRoom
		
		super.init(background: background)
		
        delegate = d
		doneButton.target = self
		doneButton.releaseAction = "doneTapped"
		doneButton.titleLabel?.font = Fonts.caption1
		
		if (selectedRoom != nil) {
			doneButton.title = Strings.done
		} else {
			doneButton.title = Strings.cancel
		}
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		tableViewController = RoomPickerTableViewController(containingRoomPicker: self)
		self.addChildViewController(tableViewController!)
		self.view.addSubview(tableViewController!.view)
		
		view.addSubview(doneButton)
		
		setupConstraints()
	}
	
	override func setupConstraints() {
		view.sav_pinView(doneButton, withOptions: .ToBottom | .Horizontally, withSpace: 0)
		view.sav_setHeight(Sizes.row * 8, forView: doneButton, isRelative: false)
		view.sav_pinView(self.tableViewController!.tableView, withOptions: .ToTop | .Horizontally, withSpace: 0)
		view.sav_pinView(self.tableViewController!.tableView, withOptions: .ToTop, ofView:doneButton, withSpace: 0)
	}
	
	func doneTapped() {
		if let selectedRoom = selectedRoom {
			delegate?.roomPicker(self, selectedRoom:selectedRoom)
		} else {
			delegate?.roomPickerCanceledSelection(self)
		}
	}
    
    func addRoomTapped() {
        let addRoom = AddRoomViewController()
        navigationController?.pushViewController(addRoom, animated: true)
    }
}