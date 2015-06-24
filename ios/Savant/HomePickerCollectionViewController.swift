//
//  HomePickerCollectionViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/1/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

enum PanDirection {
    case Left
    case Right
    case Up
    case Down
}

class HomePickerCollectionViewController: FakeNavBarModelCollectionViewController, HomePickerConnectionDelegate {
    var pickerModel: HomePickerDataModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerModel.connectionDelegate = self
        setRightTitle("+")
        rightButton.target = self
        rightButton.releaseAction = "addButtonPressed:"
        collectionView?.delaysContentTouches = false
        collectionView?.backgroundColor = UIColor.clearColor()
        collectionView?.backgroundView = UIView()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDataSource() -> DataSource {
        return pickerModel
    }
    
    override func reloadData() {
        super.reloadData()
        updateTitle()
    }
    
    override func insertSections(sections: NSIndexSet, animation: UITableViewRowAnimation) {
        super.insertSections(sections, animation: animation)
        updateTitle()
    }
    
    func updateTitle() {
        title = Strings.homesFound(pickerModel.numberOfSystems())
    }
    
    override func registerCells() {
        registerCell(type: 0, cellClass: HomePickerCell.self)
        registerCell(type: 1, cellClass: HomePickerCell.self)
    }
    
    func addButtonPressed(sender: SCUButton) {
        RootCoordinator.transitionToState(.HostOnboarding)
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: HomePickerCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! HomePickerCell
        cell.contentView.layer.cornerRadius = 3.0
        cell.contentView.layer.masksToBounds = true
        
        if cell.type == .HostNotFound {
            if let button = cell.mainButton {
                pickerModel.listenToRetryButtonAtIndexPath(button, indexPath: indexPath)
            }
        } else {
            if let button = cell.mainButton {
                pickerModel.listenToButtonAtIndexPath(button, indexPath: indexPath)
            }
        }
        
        if cell.type == .Onboarding {
            if let skipButton = cell.linkButton {
                pickerModel.listenToSkipOnboardingButtonAtIndexPath(skipButton, indexPath: indexPath)
            }
        }
        
        if let button = cell.mainButton {
            pickerModel.listenToCancelButtonAtIndexPath(button, indexPath: indexPath)
        }
        
        return cell
    }
    
    override func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {
        super.configureLayoutWithOrientation(orientation)
        let layout = collectionView?.collectionViewLayout as! FullscreenCardFlowLayout
        
        if UIDevice.isPhone() {
            layout.width = Sizes.columnForOrientation(orientation) * 40;
            layout.height = Sizes.row * 52;
        } else {
            if (orientation == .Portrait || orientation == .PortraitUpsideDown) {
                layout.width = Sizes.columnForOrientation(orientation) * 30;
                layout.height = Sizes.row * 66;
                layout.interspace = Sizes.columnForOrientation(orientation) * 4;
            } else {
                layout.height = Sizes.row * 72;
                layout.width = Sizes.columnForOrientation(orientation) * 40;
                layout.interspace = Sizes.columnForOrientation(orientation) * 4;
            }
        }
        
        layout.invalidateLayout()
    }
    
    func showConnectButton(indexPath: NSIndexPath) {
        self.collectionView?.scrollEnabled = true
        var card = cellForIndexPath(indexPath)
        card?.mainButton?.setProgressState(.Normal)
    }
    
    func showProgressSpinner(show: Bool, indexPath: NSIndexPath) {
        self.collectionView?.scrollEnabled = false
        var card = cellForIndexPath(indexPath)
        card?.mainButton?.setProgressState(.Spinning)
    }

    func updateProgressStatusBar(progress: CGFloat, indexPath: NSIndexPath) {
        var card = cellForIndexPath(indexPath)
        card?.mainButton?.setProgress(progress)
    }
    
    private func cellForIndexPath(indexPath: NSIndexPath) -> HomePickerCell? {
        return collectionView?.cellForItemAtIndexPath(indexPath) as? HomePickerCell
    }

    override func handleBack() {
        if let previousState = RootCoordinator.previousState {
            switch previousState {
            case .SignIn:
                RootCoordinator.transitionToState(.SignIn)
            case .Interface:
                Savant.control().loadPreviousConnection()
            default:
                break
            }
        }
    }
}
