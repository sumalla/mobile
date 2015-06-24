//
//  AddRoomTableViewController.swift
//  Savant
//
//  Created by Julian Locke on 5/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class AddRoomTableViewController: ModelTableViewController {
    
    var delegate:AddRoomViewController?
    weak var selectedRoom:SAVRoom?
    var roomName:String?
    let datasource = AddRoomViewModel()
    var textField:ErrorTextField?
    var tapRecognizer:UITapGestureRecognizer?
    
    init() {
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
        
        tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, 200, Sizes.row * 8))
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = UIColor.clearColor()
        
        var label = UILabel(frame: CGRectZero)
        label.font = Fonts.caption1
        label.textColor = Colors.color1shade3
        label.text = "ROOM NAME"
        
        textField = ErrorTextField(frame: CGRectZero, style: ErrorTextFieldStyle.Plain)
        textField?.placeholder = "Name your room"
        textField?.returnHandler = {
            self.textField?.endEditing(true)
            self.roomName = self.textField?.text
            self.tapRecognizer?.removeTarget(self, action: "textFieldEndEditing")
            if let tr = self.tapRecognizer {
                self.view.removeGestureRecognizer(tr)
            }
            self.tapRecognizer = nil
        }
        textField?.beginHandler = {
            self.tapRecognizer = UITapGestureRecognizer(target: self, action: "textFieldEndEditing")
            if let tr = self.tapRecognizer {
                self.view.addGestureRecognizer(tr)
            }
        }

        tableView.tableHeaderView?.addSubview(label)
        tableView.tableHeaderView?.sav_pinView(label, withOptions: .ToTop, withSpace: 14)
        tableView.tableHeaderView?.sav_pinView(label, withOptions: .CenterX)
        
        tableView.tableHeaderView?.addSubview(textField!)
        tableView.tableHeaderView?.sav_pinView(textField!, withOptions: .ToTop, withSpace: 34)
        tableView.tableHeaderView?.sav_pinView(textField!, withOptions: .CenterX)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func registerCells() {
        registerCell(type: AddRoomCellType.Switch.rawValue, cellClass: PickRoomCellSwitch.self)
        registerCell(type: PickRoomCellType.Add.rawValue, cellClass: PickRoomCellAdd.self)
    }
    
    override func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = Colors.color1shade1
        
        let item = datasource.itemForIndexPath(indexPath)
        if let room = item?.dataObject as? SAVRoom, cell = cell as? PickRoomCellSwitch {
        if (selectedRoom == room) {
                cell.switchView.setOn(true, animated: false)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PickRoomCellSwitch {
            
            let modelItem = datasource.itemForIndexPath(indexPath)
            var roomToSelect:SAVRoom?
            
            if selectedRoom == nil {
                roomToSelect = modelItem?.dataObject as? SAVRoom
            } else {
                if cell.switchView.on {
                    roomToSelect = nil
                }
                else {
                    roomToSelect = modelItem?.dataObject as? SAVRoom
                }
                
                for cell in tableView.visibleCells() as! [PickRoomCell] {
                    if let switchCell = cell as? PickRoomCellSwitch {
                        if (switchCell.switchView.on) {
                            switchCell.switchView.setOn(false, animated: true)
                        }
                    }
                }
            }
            
            if roomToSelect != nil {
                cell.switchView.setOn(true, animated: true)
            }
            
            selectedRoom = roomToSelect
            
            textFieldEndEditing()
            roomName = textField?.text
            
            delegate?.roomCreated(selectedRoom)
        }
    }
    
    internal func textFieldEndEditing() {
        textField?.endEditing(true)
    }
}
