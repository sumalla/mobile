//
//  RoomsTableController.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class PullToNavigateHeaderView: UICollectionReusableView {
    var label: UILabel!
    
    init () {
        super.init(frame: CGRectZero)
        label = UILabel(frame: CGRectMake(0, 0, 0, Sizes.row * 5))
        label.textColor = Colors.color1shade1
        label.textAlignment = .Center
        label.text = "Navigate to Home"
        self.addSubview(label)
        self.sav_addFlushConstraintsForView(label)
    }
    
     override convenience init(frame: CGRect) {
        self.init()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, Sizes.row * 5)
    }
}

class RoomsCollectionController: ModelCollectionViewController {

    var roomsModel: RoomsDataModel!
    let navBar = SCUGradientView(frame: CGRectZero, andColors: nil)
    var homeOverviewButton = SCUButton()
    var settingsButton = SCUButton()
    var personButton = SCUButton()
    let threshold: CGFloat = -100.0
    var header = PullToNavigateHeaderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        
        navBar.colors = [Colors.color2shade1, Colors.color2shade1.colorWithAlphaComponent(0.8), Colors.color2shade2]
        navBar.locations = [0.25, 0.8, 1]
        view.addSubview(navBar)
        view.sav_pinView(navBar, withOptions: .ToTop | .Horizontally)
        view.sav_setHeight(contentOffsetTop(), forView: navBar, isRelative: false)

        collectionView?.contentInset = UIEdgeInsetsMake(Sizes.row * 8 - header.intrinsicContentSize().height, 0, 0, 0)
        
        self.collectionView!.registerClass(PullToNavigateHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PullToNavigateHeaderView")
        let flow = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        flow.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.view.frame), header.intrinsicContentSize().height)

        let homeOverviewImage = UIImage(named: "HomeOverview")
        homeOverviewButton = SCUButton(style: .Light, image: homeOverviewImage)
        homeOverviewButton.target = self
        homeOverviewButton.releaseAction = Selector("home:")
        homeOverviewButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeOverviewButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)

        navBar.addSubview(homeOverviewButton)
        navBar.sav_pinView(homeOverviewButton, withOptions: .CenterX)
        navBar.sav_pinView(homeOverviewButton, withOptions: .CenterY, withSpace: Sizes.row)

        personButton = SCUButton(style: .Light, image: UIImage(named: "Person"))
        personButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        personButton.target = self
        personButton.releaseAction = "showUserProfile:"

        navBar.addSubview(personButton)
        navBar.sav_pinView(personButton, withOptions: .CenterY, withSpace: Sizes.row)
        navBar.sav_pinView(personButton, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)

        settingsButton = SCUButton(style: .Light, image: UIImage(named: "SettingsGear"))
        settingsButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        settingsButton.target = self
        settingsButton.releaseAction = "settings:"

        navBar.addSubview(settingsButton)
        navBar.sav_pinView(settingsButton, withOptions: .CenterY, withSpace: Sizes.row)
        navBar.sav_pinView(settingsButton, withOptions: .ToRight, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        for cell in visibleRoomCells() {
            cell.setHidden(true, animated: false, delay: 0)

            if let sc = cell.serviceSelector {
                sc.viewWillDisappear(animated)
            }
        }
        
        header.label.frame.size.width = CGRectGetWidth(self.view.frame)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)

        for cell in visibleRoomCells() {
            cell.setHidden(true, animated: false, delay: 0)

            if let sc = cell.serviceSelector {
                sc.viewWillAppear(animated)
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        for cell in visibleRoomCells() {
            cell.setHidden(false, animated: true, delay: 0)

            if let sc = cell.serviceSelector {
                sc.viewDidAppear(animated)
            }
        }
    }

    private func visibleRoomCells() -> [RoomCell] {
        var cells = [RoomCell]()

        if let visibleIndexPaths = collectionView?.indexPathsForVisibleItems() as? [NSIndexPath] {
            for indexPath in sorted(visibleIndexPaths) {
                if let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? RoomCell {
                    cells.append(cell)
                }
            }
        }

        return cells
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        var opacity = min(fabs(scrollView.contentOffset.y + contentOffsetTop() - header.intrinsicContentSize().height), 100.0) / 100.0
        self.header.alpha = opacity
 
        if scrollView.panGestureRecognizer.numberOfTouches() > 0 && scrollView.contentOffset.y < 0 {
            personButton.alpha = 1.0 - opacity
            settingsButton.alpha = 1.0 - opacity
        } else {
            personButton.alpha = 1.0
            settingsButton.alpha = 1.0
        }
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y + contentOffsetTop() - header.intrinsicContentSize().height < threshold {
            UIView.animateWithDuration(0.5) {
                scrollView.contentOffset.y = CGRectGetHeight(scrollView.frame)
            }
            home(nil)
        }
        
    }
    
    func contentOffsetTop() -> CGFloat {
        return Sizes.row * 8 + 20.0
    }
    
    func updateHomeIcon() {
        home(nil)
    }

    func showUserProfile(sender: UIBarButtonItem?) {
        roomsModel.coordinator.transitionToState(.UserProfile)
    }

    func settings(sender: UIBarButtonItem?) {
        roomsModel.coordinator.transitionToState(.Settings)
    }

    func home(sender: UIBarButtonItem?) {
        roomsModel.coordinator.transitionToState(.House)
    }

    override func viewDataSource() -> DataSource {
        return roomsModel
    }

    override func registerCells() {
        registerCell(type: 0, cellClass: RoomCell.self)
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "PullToNavigateHeaderView", forIndexPath: indexPath) as! PullToNavigateHeaderView
        header.frame = header.label.frame
        return header
    }

    override func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {
        if let layout = collectionView?.collectionViewLayout as? VerticalFlowLayout {
            if UIDevice.isPhone() {
                layout.interspace = Sizes.row / 2
                layout.height = Sizes.row * 44
                layout.horizontalInset = 0
                layout.columns = 1
            } else {
                layout.height = Sizes.row * 44
                layout.interspace = Sizes.row * 1

                if UIInterfaceOrientationIsPortrait(orientation) {
                    layout.columns = 1
                    layout.horizontalInset = 0
                } else {
                    layout.columns = 2
                    layout.horizontalInset = Sizes.columnForOrientation(orientation) * 2
                }
            }

            layout.invalidateLayout()

            NSTimer.sav_scheduledBlockWithDelay(0) {
                self.header.alpha = 0
            }
        }
    }

}
