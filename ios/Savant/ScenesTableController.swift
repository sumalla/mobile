//
//  ScenesTableController.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import ModelItem

class ScenesTableController: ModelTableViewController {

    var scenesModel: ScenesDataModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = Sizes.row * 22
        title = NSLocalizedString("Scenes", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "<", style: .Plain, target: self, action: "back:")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.prompt = scenesModel.roomFilter?.roomId
    }

    func back(sender: UIBarButtonItem) {
        scenesModel.coordinator.transitionBack()
    }

    override func viewDataSource() -> DataSource {
        return scenesModel
    }

    override func registerCells() {
        registerCell(type: 0, cellClass: SceneCell.self)
        registerCell(type: 1, cellClass: MultiLineTableCell.self)
    }

    override func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.selectionStyle = .None
    }

}
