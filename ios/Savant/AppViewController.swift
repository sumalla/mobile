//
//  AppViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/17/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class AppViewController: UIViewController {

    func loadInitialView() {
        if Savant.control().loadPreviousConnection() {
            RootCoordinator.transitionToState(.Interface)
        } else if Savant.cloud().hasCloudCredentials() {
            RootCoordinator.transitionToState(.HomePicker)
        } else {
            RootCoordinator.transitionToState(.SignIn)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Savant.images().purgeMemory()
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.isPad() {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
        }
    }

}

class ShakeViewController: AppViewController {

    var state = 0
    var columnView = UIView()
    var rowView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDebugViews()
        self.becomeFirstResponder()
    }

    func setupDebugViews() {
        columnView.removeFromSuperview()
        rowView.removeFromSuperview()
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let numberOfRows: Int = Int(CGRectGetHeight(screenSize) / Sizes.row)

        let rows = map(1...numberOfRows) {
            return UIView.sav_viewWithColor(($0 % 2) == 0 ? UIColor.blueColor().colorWithAlphaComponent(0.25) : UIColor.redColor().colorWithAlphaComponent(0.25))
        }

        if rows.count != 0 {
            let configuration: SAVViewDistributionConfiguration = SAVViewDistributionConfiguration()
            configuration.interSpace = 0;
            configuration.distributeEvenly = true;
            configuration.separatorSize = 0
            configuration.vertical = true

            rowView = UIView.sav_viewWithEvenlyDistributedViews(rows as [AnyObject], withConfiguration: configuration)
            rowView.userInteractionEnabled = false
        }

        var columnCount = UIInterfaceOrientationIsPortrait(UIDevice.interfaceOrientation()) ? 62 : 74
        
        if UIDevice.isPhone() {
            columnCount = 50
        }
        
        let columns = map(1...columnCount) {
            return UIView.sav_viewWithColor(($0 % 2) == 0 ? UIColor.blueColor().colorWithAlphaComponent(0.25) : UIColor.greenColor().colorWithAlphaComponent(0.25))
        }

        if columns.count != 0 {
            let configuration: SAVViewDistributionConfiguration = SAVViewDistributionConfiguration()
            configuration.interSpace = 0;
            configuration.distributeEvenly = true;
            configuration.separatorSize = 0

            columnView = UIView.sav_viewWithEvenlyDistributedViews(columns as [AnyObject], withConfiguration: configuration)
            columnView.userInteractionEnabled = false
        }
    }
    
    func setViewState(newState: Int) {
        state = newState
        switch newState {
        case 0:
            UIWindow.sav_topView().addSubview(columnView)
            UIWindow.sav_topView().sav_addFlushConstraintsForView(columnView)
            state++
            break
        case 1:
            UIWindow.sav_topView().addSubview(rowView)
            UIWindow.sav_topView().sav_addFlushConstraintsForView(rowView)
            state++
            break
        case 2:
            state = 0
            break
        default:
            break
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.animateInterfaceRotationChangeWithCoordinator(coordinator, block: { [unowned self] (orientation: UIInterfaceOrientation) -> Void  in
            self.setupDebugViews()
            self.setViewState(2)
        })
    }

    override func canBecomeFirstResponder() -> Bool {
        return true;
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {

        if motion == .MotionShake {
            columnView.removeFromSuperview()
            rowView.removeFromSuperview()

            setViewState(state)
        }
    }
    
}
