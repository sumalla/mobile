//
//  HomeMonitorSettingsViewController.swift
//  Savant
//
//  Created by Joseph Ross on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class HomeMonitorSettingsViewController: UITableViewController, UITextFieldDelegate {
    
    var powerSwitch:UISwitch!
    var detectionSwitch:UISwitch!
    var privacySwitch:UISwitch!
    var cameraTitleField:UITextField!
    
    enum Sections: Int {
        case Camera
        case Protect
        case Sense
        case Remove
        case Count
    }
    
    enum CameraRows: Int {
        case Name
        case Location
        case Power
        case Count
    }
    
    enum ProtectRows: Int {
        case Title
        case Detection
        case Description
        //case Sensitivity
        case Count
    }
    
    enum SenseRows: Int {
        case Title
        case Privacy
        case Description
        case Count
    }
    
    enum RemoveRows: Int {
        case Remove
        case Count
    }
    
    override func viewDidLoad() {
        tableView.backgroundColor = Colors.color5shade1
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = .None
        tableView.rowHeight = 59
        tableView.estimatedRowHeight = 59
        
        powerSwitch = orangeSwitch()
        detectionSwitch = orangeSwitch()
        privacySwitch = orangeSwitch()
        cameraTitleField = UITextField()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .Camera:
            switch CameraRows(rawValue: indexPath.row)! {
            case .Name:
                return cameraTitleCell()
            case .Location:
                return cameraLocationCell()
            case .Power:
                return cameraPowerCell()
            default:
                return UITableViewCell()
            }
        case .Protect:
            switch ProtectRows(rawValue: indexPath.row)! {
            case .Title:
                return protectTitleCell()
            case .Detection:
                return protectDetectionCell()
            case .Description:
                return protectDescriptionCell()
//            case .Sensitivity:
//                return protectSensitivityCell()
            default:
                return UITableViewCell()
            }
        case .Sense:
            switch SenseRows(rawValue: indexPath.row)! {
            case .Title:
                return senseTitleCell()
            case .Privacy:
                return sensePrivacyCell()
            case .Description:
                return senseDescriptionCell()
            default:
                return UITableViewCell()
            }
        case .Remove:
            switch RemoveRows(rawValue: indexPath.row)! {
            case .Remove:
                return removeButtonCell()
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if     indexPath.section == Sections.Protect.rawValue && indexPath.row == ProtectRows.Description.rawValue
            || indexPath.section == Sections.Sense.rawValue   && indexPath.row == SenseRows.Description.rawValue
            || indexPath.section == Sections.Remove.rawValue   && indexPath.row == RemoveRows.Remove.rawValue
        {
            return UITableViewAutomaticDimension
        }
        return tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > Sections.Camera.rawValue && section < Sections.Remove.rawValue {
            return 20
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = Sections(rawValue: section) {
            switch section {
            case .Camera:
                return CameraRows.Count.rawValue
            case .Protect:
                return ProtectRows.Count.rawValue
            case .Sense:
                return SenseRows.Count.rawValue
            case .Remove:
                return RemoveRows.Count.rawValue
            default:
                return 0
            }
        }
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Sections.Count.rawValue
    }
    
    func simpleGreyCell() -> UITableViewCell {
        let kSimpleGreyReuseIdentifier = "SimpleGreyCell"
        var cell:UITableViewCell
        let reusableCell:UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(kSimpleGreyReuseIdentifier) as? UITableViewCell
        
        if reusableCell != nil {
            cell = reusableCell!
            cell.contentView.subviews.map({(subview) -> Void in subview.removeFromSuperview()})
        } else {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: kSimpleGreyReuseIdentifier)
        }
        
        cell.selectionStyle = .None
        cell.accessoryView = nil
        cell.accessoryType = .None
        cell.textLabel?.text = nil
        cell.textLabel?.textColor = Colors.color1shade2
        cell.textLabel?.font = Fonts.body
        cell.detailTextLabel?.text = nil
        cell.detailTextLabel?.textColor = Colors.color1shade2
        cell.detailTextLabel?.font = Fonts.body
        cell.backgroundColor = Colors.color1shade5
        cell.separatorInset = UIEdgeInsetsZero
//        cell.contentView.addComp
        
        // Draw seperator
        
        let seperator = UIView()
        seperator.backgroundColor = Colors.color1shade6
        cell.addSubview(seperator)
        cell.sav_pinView(seperator, withOptions: .ToBottom | .ToLeft | .ToRight)
        cell.sav_setHeight(1.0, forView: seperator, isRelative: false)
         
        return cell
        
    }
    
    func cameraTitleCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        
        cameraTitleField.textColor = Colors.color1shade1
        cameraTitleField.font = Fonts.body
        cameraTitleField.text = "Joe's Camera"
        cameraTitleField.delegate = self
        cell.contentView.addSubview(cameraTitleField)
        cell.contentView.sav_pinView(cameraTitleField, withOptions: .CenterY)
        cell.contentView.sav_pinView(cameraTitleField, withOptions: .ToLeft, withSpace: 17)
        
        
        let editButton = SCUButton(image: UIImage(named: "edit"))
        editButton.color = Colors.color1shade2
        editButton.releaseCallback = {
            self.cameraTitleField.becomeFirstResponder()
        }
        
        cell.contentView.addSubview(editButton)
        cell.contentView.sav_setSize(CGSizeMake(14, 14), forView: editButton, isRelative: false)
        cell.contentView.sav_pinView(editButton, withOptions: .ToRight, ofView: cameraTitleField, withSpace: 8)
        cell.contentView.sav_pinView(editButton, withOptions: .CenterY)
        return cell
    }
    
    func cameraLocationCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.text = "Location"
        cell.detailTextLabel?.text = "Entryway"
        cell.accessoryType = .DisclosureIndicator
        return cell
    }
    
    func cameraPowerCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.text = "Power"
        cell.accessoryView = powerSwitch
        return cell
    }
    
    func protectTitleCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.textColor = Colors.color1shade1
        cell.textLabel?.text = "Protect Mode"
        return cell
    }
    
    func protectDetectionCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.textColor = Colors.color1shade3
        cell.textLabel?.text = "Detection"
        cell.accessoryView = detectionSwitch
        return cell
    }
    
    func protectDescriptionCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        let descriptionLabel = UILabel()
        cell.contentView.addSubview(descriptionLabel)
        cell.contentView.sav_addFlushConstraintsForView(descriptionLabel, withPadding:17)
        descriptionLabel.textColor = Colors.color1shade3
        descriptionLabel.font = Fonts.caption1
        descriptionLabel.numberOfLines = 5
        descriptionLabel.text = "In Protect Mode, your camera scans for people. You will be notified and clips will be generated of these events."
        return cell
    }
    
    func protectSensitivityCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        return cell
    }
    
    func senseTitleCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.textColor = Colors.color1shade1
        cell.textLabel?.text = "Sense Mode"
        return cell
    }
    
    func sensePrivacyCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.textLabel?.textColor = Colors.color1shade3
        cell.textLabel?.text = "Privacy"
        cell.accessoryView = privacySwitch
        return cell
    }
    
    func senseDescriptionCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        let descriptionLabel = UILabel()
        cell.contentView.addSubview(descriptionLabel)
        cell.contentView.sav_addFlushConstraintsForView(descriptionLabel, withPadding:17)
        descriptionLabel.textColor = Colors.color1shade3
        descriptionLabel.font = Fonts.caption1
        descriptionLabel.numberOfLines = 8
        descriptionLabel.text = "The camera will not stream a live feed to respect your privacy.\n\nDetects people in the home so that you can use your presence to activate Scenes. The camera will not scan actively or cut clips to notify you of people."
        return cell
    }
    
    func removeButtonCell() -> UITableViewCell {
        let cell = simpleGreyCell()
        cell.backgroundColor = Colors.color5shade1
        let removeButton = SCUButton(title: "REMOVE")
        removeButton.titleLabel?.font = Fonts.body
        removeButton.color = Colors.color4shade1
        removeButton.layer.borderColor = Colors.color1shade4.CGColor
        removeButton.layer.borderWidth = 1
        removeButton.layer.cornerRadius = 3
        cell.contentView.addSubview(removeButton)
        cell.contentView.sav_addFlushConstraintsForView(removeButton, withPadding: 30)
        
        return cell
    }
    
    func orangeSwitch() -> UISwitch {
        let control = UISwitch()
        control.onTintColor = Colors.color4shade1
        control.on = true
        return control
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
