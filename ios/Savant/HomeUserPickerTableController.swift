//
//  HomeUserPickerTableController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class HomeUserPickerTableController: FakeNavBarModelTableViewController {

    var pickerModel: HomeUserPickerDataModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Local users", comment: "").uppercaseString
        tableView.rowHeight = 60
        tableView.backgroundColor = UIColor.clearColor()
        fadeTopCells = true
    }

    override func registerCells() {
        registerCell(type: 0, cellClass: RightImageCell.self)
    }

    override func viewDataSource() -> DataSource {
        return pickerModel
    }

    override func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()

        if let cell = cell as? DefaultCell {
            cell.labelInset = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5
            cell.customSelectionStyle = .Lighten
        }
    }

    override func handleBack() {
        pickerModel.coordinator.transitionToState(.HomePicker)
    }

}