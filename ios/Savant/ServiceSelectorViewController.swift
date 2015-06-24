//
//  ServiceSelectorViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class ServiceSelectorViewController: ModelCollectionViewController {

    var model: ServiceSelectorModel!
    var compact = false

    override func viewDataSource() -> DataSource {
        return model
    }

    override func registerCells() {
        if compact {
            registerCell(type: 0, cellClass: ServiceSelectorCollectionViewCellCompact.self)
        } else {
            registerCell(type: 0, cellClass: ServiceSelectorCollectionViewCellFull.self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.indicatorStyle = .White
        collectionView?.backgroundColor = UIColor.clearColor()
        
        var longPress = UILongPressGestureRecognizer()
        longPress.minimumPressDuration = 0.25
        longPress.addTarget(self, action: "handleLongPress:")
        
        collectionView?.addGestureRecognizer(longPress)
    }

    override func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {
        if let layout = self.collectionViewLayout as? SCUPagingHorizontalFlowLayout {
            if compact {
                if UIDevice.isPhone() {
                    layout.numberOfColums = 4
                } else {
                    if UIInterfaceOrientationIsPortrait(orientation) {
                        layout.numberOfColums = 5
                    } else {
                        layout.numberOfColums = 4
                    }
                }

                // Don't invalidate the layout if it's compact
            } else {
                if UIDevice.isPhone() {
                    layout.numberOfColums = 4
                } else {
                    if UIInterfaceOrientationIsPortrait(orientation) {
                        layout.numberOfColums = 5
                    } else {
                        layout.numberOfColums = 6
                    }
                }

                NSTimer.sav_scheduledBlockWithDelay(0) {
                    layout.invalidateLayout()
                }
            }

            self.collectionView?.contentOffset = CGPoint(x: 0, y: 0);
        }
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .Began {

            let location = recognizer.locationInView(self.collectionView)
            var indexPath = self.collectionView?.indexPathForItemAtPoint(location)

            let serviceGroups = self.model.serviceGroupsForIndexPath(indexPath!)
            let popOver = PopoverMicroInteractionController(serviceGroups: serviceGroups!, gesture: recognizer)
            
            if let popOver = popOver, indexPath = indexPath {
                var view = collectionView?.cellForItemAtIndexPath(indexPath)
                let layout = self.collectionViewLayout as? SCUPagingHorizontalFlowLayout
                var index = Int(indexPath.row) % (Int(layout!.numberOfColums))
                
                popOver.showFromView(view!, index: index, columns: Int(layout!.numberOfColums), columnWidth: (CGRectGetWidth(collectionView!.bounds) - (layout!.pageInset)) / CGFloat(layout!.numberOfColums), completionClosure: { () -> () in
                    recognizer.addTarget(self, action: "handleLongPress:")
                    self.collectionView?.addGestureRecognizer(recognizer)
                })
            }

        }
    }

}
