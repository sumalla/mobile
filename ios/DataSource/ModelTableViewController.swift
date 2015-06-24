//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public class ModelTableViewController: UITableViewController {
    public var fadeTopCells = false
    public var fadeBottomCells = false
}

extension ModelTableViewController: DataSourceController {

    public func viewDataSource() -> DataSource {
        fatalError("implement")
    }

    public func registerCells() {

    }

    public func configure(#cell: UITableViewCell, indexPath: NSIndexPath) {
        
    }

}

extension ModelTableViewController {

    public func registerCell(#type: Int, cellClass: AnyClass!) {
        tableView.registerClass(cellClass, forCellReuseIdentifier: String(type))
    }

    private func dequeueCellWithType(type: Int, indexPath: NSIndexPath) -> DataSourceTableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(String(type), forIndexPath: indexPath) as! DataSourceTableViewCell
    }

}

extension ModelTableViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        viewDataSource().reloader = self
        registerCell(type: 0, cellClass: DataSourceTableViewCell.self) /* Register a default cell */
        registerCells()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewDataSource().willAppear()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewDataSource().didAppear()
        
        var visibleCells = visibleCellsWithinRect(tableView.frame)
        for cell in visibleCells {
            cell.alpha = 1.0;
        }
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        viewDataSource().willDisappear()
    }

    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewDataSource().didDisappear()
    }
    
    public override func scrollViewDidScroll(scrollView: UIScrollView) {
        if fadeBottomCells || fadeTopCells {
        
            // Fades out top and bottom cells in table view as they leave the screen
            var rect = tableView.frame
            rect.origin.y = rect.origin.y + tableView.contentInset.top
            
            var visibleCells = visibleCellsWithinRect(rect)
 
            if visibleCells.count != 0 {
                let topCell = visibleCells.first
                let bottomCell = visibleCells.last

                /* Make sure other cells stay opaque */
                /* Avoids issues with skipped method calls during rapid scrolling */
                for cell in visibleCells {
                    cell.alpha = 1.0;
                }
                
                let cellHeight = topCell!.frame.height - 1// To allow for typical separator line height
                let tableViewTopPosition: CGFloat = tableView.frame.origin.y + tableView.contentInset.top
                let tableViewBottomPosition: CGFloat = tableView.frame.origin.y + tableView.frame.height

                /* Get content offset to set opacity */
                let topCellPositionInTableView = tableView.rectForRowAtIndexPath(tableView.indexPathForCell(topCell!)!)
                let bottomCellPositionInTableView = tableView.rectForRowAtIndexPath(tableView.indexPathForCell(bottomCell!)!)
                let topCellPosition: CGFloat = tableView.convertRect(topCellPositionInTableView, toView: tableView.superview).origin.y
                let bottomCellPosition: CGFloat = tableView.convertRect(bottomCellPositionInTableView, toView: tableView.superview).origin.y + cellHeight
                
                /* Set opacity based on amount of cell that is outside of view */
                /* Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen, 2.0 for fully transparent when the cell is half off the screen, etc) */
                let modifier: CGFloat = 1.5
                
                let topCellOpacity = (1.0 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier)
                let bottomCellOpacity = (1.0 - ((tableViewBottomPosition - bottomCellPosition) / cellHeight) * modifier)
                
                if fadeTopCells && topCell != nil {
                    topCell?.alpha = topCellOpacity
                }
                
                if fadeBottomCells && bottomCell != nil && bottomCell != topCell {
                    bottomCell?.alpha = bottomCellOpacity
                }
                
            }
        }
    }
    
    private func visibleCellsWithinRect(rect: CGRect) -> [UITableViewCell] {
        var visiblePaths = tableView.indexPathsForVisibleRows() as! [NSIndexPath]
        var visibleCells = [UITableViewCell]()
        
        for indexPath in visiblePaths {
            var rowRect = tableView.rectForRowAtIndexPath(indexPath)
            rowRect = tableView.convertRect(rowRect, toView: tableView.superview)
            
            if CGRectIntersectsRect(rect, rowRect) {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                    visibleCells.append(cell)
                }
            }
        }
        
        return visibleCells
    }

}

extension ModelTableViewController: Reloader {

    public func performUpdates(updates: ((reloader: Reloader) -> ())) {
        tableView.beginUpdates()
        updates(reloader: self)
        tableView.endUpdates()
    }

    public func reloadData() {
        tableView.reloadData()
    }

    public func reloadIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }

    public func reloadSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        tableView.reloadSections(sections, withRowAnimation: animation)
    }

    public func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }

    public func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }
    
    public func insertSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        tableView.insertSections(sections, withRowAnimation: animation)
    }
    
    public func deleteSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        tableView.deleteSections(sections, withRowAnimation: animation)
    }

}

extension ModelTableViewController {

    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewDataSource().numberOfSections()
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rows = viewDataSource().numberOfItemsInSection(section) {
            return rows
        } else {
            return 0
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let modelItem = viewDataSource().itemForIndexPath(indexPath) {
            let cell = dequeueCellWithType(modelItem.type, indexPath: indexPath)
            cell.configureWithItem(modelItem)
            configure(cell: cell, indexPath: indexPath)
            return cell
        } else {
            return dequeueCellWithType(0, indexPath: indexPath)
        }
    }

    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewDataSource().headerTitleForSection(section)
    }

    public override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewDataSource().footerTitleForSection(section)
    }

}

extension ModelTableViewController {

    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let modelItem = viewDataSource().itemForIndexPath(indexPath) {
            viewDataSource().selectItemAtIndexPath(indexPath, modelItem: modelItem)
        }

        if viewDataSource().deselectItemAtIndexPath(indexPath) {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

}
