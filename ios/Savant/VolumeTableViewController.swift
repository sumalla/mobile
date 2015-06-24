//
//  VolumeTableViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class VolumeTableViewController: ModelTableViewController {
    
    private let volumeModel: VolumeModel
    var numberOfItemsDidChangeCallback: ((numberOfItems: Int) -> ())?
    
    init(volumeModel vm: VolumeModel) {
        volumeModel = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.clearColor()
        tableView.rowHeight = Sizes.row * 14
    }
    
    override func registerCells() {
        registerCell(type: VolumeModelCellType.Discrete.rawValue, cellClass: DiscreteVolumeCell.self)
        registerCell(type: VolumeModelCellType.Relative.rawValue, cellClass: VolumeCell.self)
        registerCell(type: VolumeModelCellType.Master.rawValue, cellClass: MasterVolumeCell.self)
    }
    
    override func viewDataSource() -> DataSource {
        return volumeModel
    }
    
    override func reloadData() {
        super.reloadData()
        
        if tableView.numberOfSections() == 1 {
            let numberOfItems = tableView.numberOfRowsInSection(0)
            let totalCellHeight = CGFloat(numberOfItems) * tableView.rowHeight
                
            if let numberOfItemsDidChangeCallback = numberOfItemsDidChangeCallback {
                numberOfItemsDidChangeCallback(numberOfItems: numberOfItems)
            }
            
            let inset = tableView.frame.height - totalCellHeight
            
            if inset > 0 {
                tableView.scrollEnabled = false
            } else {
                tableView.scrollEnabled = true
            }
            
            tableView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0)
        }
    }
    
    func isTapOnCell(tap: UITapGestureRecognizer) -> Bool {
        if let cells = tableView.visibleCells() as? [UITableViewCell] {
            for cell in cells {
                let location = tap.locationInView(cell)
                
                if cell.pointInside(location, withEvent: nil) {
                    return true
                }
            }
        }
        
        return false
    }
    
    override func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
        if let type = volumeModel.modelTypeForIndexPath(indexPath) {
            switch type {
            case VolumeModelCellType.Discrete.rawValue:
                if let cell = cell as? DiscreteVolumeCell {
                    volumeModel.listenToSlider(cell.slider, indexPath: indexPath)
                    volumeModel.listenToMuteButton(cell.muteButton, global: false, indexPath: indexPath)
                }
            case VolumeModelCellType.Relative.rawValue:
                if let cell = cell as? RelativeVolumeCell {
                    volumeModel.listenToButtons(decrementButton: cell.decrementButton, incrementButton: cell.incrementButton, global: false, indexPath: indexPath)
                    volumeModel.listenToMuteButton(cell.muteButton, global: false, indexPath: indexPath)
                }
            case VolumeModelCellType.Master.rawValue:
                if let cell = cell as? MasterVolumeCell {
                    volumeModel.listenToButtons(decrementButton: cell.decrementButton, incrementButton: cell.incrementButton, global: true, indexPath: indexPath)
                    volumeModel.listenToMuteButton(cell.muteButton, global: true, indexPath: indexPath)
                }
            default:
                break
            }
        }
    }

}
