//
//  AddRoomViewController.swift
//  Savant
//
//  Created by Julian Locke on 5/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

protocol AddRoomDelegate {
    func roomCreated(room: SAVRoom?)
}

class AddRoomViewController: RoomPickerBaseViewController {
    
    let tableViewController = AddRoomTableViewController()
    let doneButton = SCUButton(style: .PinnedButton)
    let cancelButton = SCUButton(style: .PinnedButton)

    var newRoom:SAVRoom?
    
	init(backgroundImage: RoomPickerViewControllerBackground = .Default) {
        super.init(background: backgroundImage)
        
        tableViewController.delegate = self
        
        doneButton.title = "Done"
        doneButton.target = self
        doneButton.releaseAction = "doneTapped"
        doneButton.titleLabel?.font = Fonts.caption1
        
        cancelButton.title = "Cancel"
        cancelButton.target = self
        cancelButton.releaseAction = "cancelTapped"
        cancelButton.titleLabel?.font = Fonts.caption1
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
		
		super.viewDidLoad()
		
        view.addSubview(tableViewController.tableView)
        view.backgroundColor = UIColor.clearColor()
        
        setupConstraints()
    }
    
    override func setupConstraints() {
        let views = [doneButton, cancelButton]
        
        var config = SAVViewDistributionConfiguration()
        config.interSpace = 0
        config.fixedHeight = Sizes.row * 8
        config.distributeEvenly = true
        config.vertical = false
        
        let container = UIView.sav_viewWithEvenlyDistributedViews(views, withConfiguration: config)
        
        view.addSubview(container)
        
        view.sav_pinView(container, withOptions: .ToBottom | .Horizontally, withSpace: 0)
        view.sav_pinView(self.tableViewController.tableView, withOptions: .ToTop | .Horizontally, withSpace: 0)
        view.sav_pinView(self.tableViewController.tableView, withOptions: .ToTop, ofView:doneButton, withSpace: 0)
    }
    
    func doneTapped() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func cancelTapped() {
        navigationController?.popViewControllerAnimated(true)
    }
}

extension AddRoomViewController: AddRoomDelegate {
    func roomCreated(room: SAVRoom?) {
        newRoom = room
		Savant.hostServices()
    }
}
