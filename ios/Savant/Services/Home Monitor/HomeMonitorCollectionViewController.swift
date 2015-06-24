//
//  HomeMonitorTableTableViewController.swift
//  Savant
//
//  Created by Joseph Ross on 3/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class HomeMonitorCollectionViewController: ModelCollectionViewController, HomeMonitorModelDelegate {

    var model:HomeMonitorModel! = nil
    
    init(model:HomeMonitorModel) {
        let layout = VerticalFlowLayout()
        super.init(collectionViewLayout:layout)
        self.model = model
        self.model.delegate = self
    }
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func registerCells() {
        registerCell(type: 0, cellClass: HomeMonitorCell.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDataSource() -> DataSource {
        return model
    }
    
    override func reloadData() {
        collectionView?.reloadData()
    }
    
    func reloadIndexPath(indexPath: NSIndexPath) {
        collectionView?.reloadItemsAtIndexPaths([indexPath])
    }
    
    func selectedMonitor(monitor: HomeMonitor) {
        parentViewController?.navigationController?.pushViewController(HomeMonitorDetailViewController(homeMonitor:monitor), animated: true)
    }
    
    override func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {
        if let layout = collectionView?.collectionViewLayout as? VerticalFlowLayout {
            layout.height = view.bounds.width / 16.0 * 9;
        }
    }
}

class HomeMonitorCell : DataSourceCollectionViewCell {
    let snapshotImage = UIImageView()
    let cameraTitle = UILabel()
    let cameraSubtitle = UILabel()
    let toggleSenseProtect = SCUButton(image: UIImage(named: "protect"))
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
    var homeMonitor:HomeMonitor? = nil
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        //selectionStyle = UITableViewCellSelectionStyle.None
        snapshotImage.contentMode = .ScaleAspectFill
        snapshotImage.clipsToBounds = true
        
        contentView.backgroundColor = Colors.color5shade1
        
        contentView.addSubview(snapshotImage)
        contentView.sav_pinView(snapshotImage, withOptions: .ToTop)
        contentView.sav_pinView(snapshotImage, withOptions: .ToLeft)
        contentView.sav_pinView(snapshotImage, withOptions: .ToRight)
        contentView.sav_pinView(snapshotImage, withOptions: .ToBottom, withSpace: Sizes.row * 2)
        
        contentView.addSubview(blurView)
        contentView.sav_pinView(blurView, withOptions: .ToTop)
        contentView.sav_pinView(blurView, withOptions: .ToLeft)
        contentView.sav_pinView(blurView, withOptions: .ToRight)
        contentView.sav_pinView(blurView, withOptions: .ToBottom, withSpace: Sizes.row * 2)
        blurView.alpha = 0
        
        cameraTitle.textColor = Colors.color1shade1
        cameraTitle.font = Fonts.subHeadline2
        
        contentView.addSubview(cameraTitle)
        contentView.sav_pinView(cameraTitle, withOptions: .ToBottom, withSpace: Sizes.row * 7)
        contentView.sav_pinView(cameraTitle, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIInterfaceOrientation.Portrait) * 4)
        
        cameraSubtitle.textColor = Colors.color1shade2
        cameraSubtitle.font = Fonts.caption1
        
        contentView.addSubview(cameraSubtitle)
        contentView.sav_pinView(cameraSubtitle, withOptions: .ToBottom, ofView:cameraTitle, withSpace: Sizes.row * 0)
        contentView.sav_pinView(cameraSubtitle, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIInterfaceOrientation.Portrait) * 4)
        
        let bottomBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.0), Colors.color5shade1.colorWithAlphaComponent(0.4)])
        contentView.addSubview(bottomBar)
        contentView.sav_pinView(bottomBar, withOptions: .ToBottom | .Horizontally)
        contentView.sav_setHeight(Sizes.row * 13, forView: bottomBar, isRelative: false)
        
        toggleSenseProtect.color = Colors.color1shade1
        toggleSenseProtect.addTarget(self, action: Selector("doToggleSenseProtect"), forControlEvents: UIControlEvents.TouchUpInside)
        contentView.addSubview(toggleSenseProtect)
        
        contentView.sav_pinView(toggleSenseProtect, withOptions: .ToBottom, withSpace: Sizes.row * 8)
        contentView.sav_pinView(toggleSenseProtect, withOptions: .ToRight, withSpace: Sizes.columnForOrientation(UIInterfaceOrientation.Portrait) * 3)
        
    }
    
    func doToggleSenseProtect() {
        if let monitor = homeMonitor {
            let willBeBlurred = monitor.mode != .Sense
            if willBeBlurred {
                monitor.updateMonitorMode(.Sense)
                toggleSenseProtect.image = UIImage(named:"sense")
                blurView.hidden = false
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.blurView.alpha = 1
                })
            } else {
                monitor.updateMonitorMode(.Protect)
                toggleSenseProtect.image = UIImage(named:"protect")
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.blurView.alpha = 0
                    }, completion: { (animated) -> Void in
                        self.blurView.hidden = true
                })
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        homeMonitor = modelItem.dataObject as? HomeMonitor
        snapshotImage.image = modelItem.image
        cameraTitle.text = modelItem.title
        cameraSubtitle.text = modelItem.subtitle?.uppercaseString
        if (homeMonitor?.mode == .Sense) {
            blurView.hidden = false
            blurView.alpha = 1.0
            toggleSenseProtect.image = UIImage(named:"sense")
        } else {
            blurView.hidden = true
            blurView.alpha = 0.0
            toggleSenseProtect.image = UIImage(named:"protect")
        }
    }
}