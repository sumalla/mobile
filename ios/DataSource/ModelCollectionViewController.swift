//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public class ModelCollectionViewController: UICollectionViewController {

}

extension ModelCollectionViewController: DataSourceController {

    public func viewDataSource() -> DataSource {
        fatalError("implement")
    }

    public func registerCells() {

    }
    
    public func configure(#cell: UICollectionViewCell, indexPath: NSIndexPath) {
        
    }

}

extension ModelCollectionViewController {

    public func registerCell(#type: Int, cellClass: AnyClass!) {
        collectionView?.registerClass(cellClass, forCellWithReuseIdentifier: String(type))
    }

    private func dequeueCellWithType(type: Int, indexPath: NSIndexPath) -> DataSourceCollectionViewCell {
        return collectionView?.dequeueReusableCellWithReuseIdentifier(String(type), forIndexPath: indexPath) as! DataSourceCollectionViewCell
    }

}

extension ModelCollectionViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLayoutWithOrientation(UIApplication.sharedApplication().statusBarOrientation)
        viewDataSource().reloader = self
        registerCell(type: 0, cellClass: DataSourceCollectionViewCell.self) /* Register a default cell */
        registerCells()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewDataSource().willAppear()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewDataSource().didAppear()
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        viewDataSource().willDisappear()
    }

    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewDataSource().didDisappear()
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        var orientation = UIInterfaceOrientation.Portrait

        if coordinator.targetTransform().b > 0 {
            switch UIApplication.sharedApplication().statusBarOrientation {
            case .Unknown:
                orientation = .Unknown;
            case .Portrait:
                orientation = .LandscapeRight;
            case .PortraitUpsideDown:
                orientation = .LandscapeLeft;
            case .LandscapeLeft:
                orientation = .Portrait;
            case .LandscapeRight:
                orientation = .PortraitUpsideDown;
            }
        } else if abs(coordinator.targetTransform().b) == 0 {
            switch UIApplication.sharedApplication().statusBarOrientation {
            case .Unknown:
                orientation = .Unknown;
            case .Portrait:
                orientation = .PortraitUpsideDown;
            case .PortraitUpsideDown:
                orientation = .Portrait;
            case .LandscapeLeft:
                orientation = .LandscapeRight;
            case .LandscapeRight:
                orientation = .LandscapeLeft;
            }
        } else {
            switch UIApplication.sharedApplication().statusBarOrientation {
            case .Unknown:
                orientation = .Unknown;
                break;
            case .Portrait:
                orientation = .LandscapeLeft;
                break;
            case .PortraitUpsideDown:
                orientation = .LandscapeRight;
                break;
            case .LandscapeLeft:
                orientation = .PortraitUpsideDown;
                break;
            case .LandscapeRight:
                orientation = .Portrait;
                break;
            }
        }

        UIView.animateWithDuration(coordinator.transitionDuration(), animations: { () -> Void in
            self.configureLayoutWithOrientation(orientation)
        })
    }

    public func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {

    }

}

extension ModelCollectionViewController: Reloader {

    public func performUpdates(updates: ((reloader: Reloader) -> ())) {
        collectionView?.performBatchUpdates({ () -> Void in
            updates(reloader: self)
        }, completion: nil)
    }

    public func reloadData() {
        collectionView?.reloadData()
    }

    public func reloadIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        collectionView?.reloadItemsAtIndexPaths(indexPaths)
    }

    public func reloadSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        collectionView?.reloadSections(sections)
    }

    public func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        collectionView?.insertItemsAtIndexPaths(indexPaths)
    }

    public func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation) {
        collectionView?.deleteItemsAtIndexPaths(indexPaths)
    }
    
    public func insertSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        collectionView?.insertSections(sections)
    }
    
    public func deleteSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        collectionView?.deleteSections(sections)
    }

}

extension ModelCollectionViewController {

    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewDataSource().numberOfSections()
    }

    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let rows = viewDataSource().numberOfItemsInSection(section) {
            return rows
        } else {
            return 0
        }
    }

    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let modelItem = viewDataSource().itemForIndexPath(indexPath) {
            let cell = dequeueCellWithType(modelItem.type, indexPath: indexPath)
            cell.configureWithItem(modelItem)
            configure(cell: cell, indexPath: indexPath)
            return cell
        } else {
            return dequeueCellWithType(0, indexPath: indexPath)
        }
    }

}

extension ModelCollectionViewController {

    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let modelItem = viewDataSource().itemForIndexPath(indexPath) {
            viewDataSource().selectItemAtIndexPath(indexPath, modelItem: modelItem)
        }
    }
    
}

