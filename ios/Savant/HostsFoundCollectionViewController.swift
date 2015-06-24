//
//  HostsFoundCollectionViewController.swift
//  Savant
//
//  Created by Stephen Silber on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class HostsFoundCollectionViewController: FakeNavBarModelCollectionViewController, HostsFoundViewDelegate {
    
    let coordinator:CoordinatorReference<HostOnboardingState>
    let model: HostsFoundCollectionViewModel
    
    init(coordinator:CoordinatorReference<HostOnboardingState>, model: HostsFoundCollectionViewModel) {
        self.coordinator = coordinator
        self.model = model
        let layout = FullscreenCardFlowLayout(interspace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4, width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 67)
        super.init(collectionViewLayout: layout)
        self.model.delegate = self
        self.model.reloader = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delaysContentTouches = false
        collectionView?.backgroundColor = UIColor.clearColor()
        collectionView?.backgroundView = UIView()
    }
    
    func hostSelected(host: ProvisionableDevice) {
        coordinator.transitionToState(.HostFoundWifi(host))
    }
    
    override func registerCells() {
        registerCell(type: 0, cellClass: HostFoundCard.self)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: HostFoundCard = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! HostFoundCard
        
        model.listenToSelectHostButton(cell.mainButton, indexPath: indexPath)
        model.listenToLinkButton(cell.linkButton, indexPath: indexPath)
        
        let tripleTap = UITapGestureRecognizer()
        tripleTap.numberOfTapsRequired = 3

        tripleTap.sav_handler = { [unowned self] (state, point) in
            cell.homeLabel.text = cell.showingUID ? self.model.homeNameForIndexPath(indexPath) : self.model.uidForIndexPath(indexPath)
            cell.showingUID = !cell.showingUID
        }
        
        cell.addGestureRecognizer(tripleTap)
        
        return cell
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.animateInterfaceRotationChangeWithCoordinator(coordinator, block: { (orientation: UIInterfaceOrientation) -> Void in
            if let layout = self.collectionView?.collectionViewLayout as? FullscreenCardFlowLayout {
                layout.height = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.row * 65: Sizes.row * 67
                layout.width = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.columnForOrientation(orientation) * 32 : Sizes.columnForOrientation(orientation) * 30
                layout.interspace = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.columnForOrientation(orientation) * 3 : Sizes.columnForOrientation(orientation) * 4
                layout.invalidateLayout()
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDataSource() -> DataSource {
        return model
    }
    
    override func handleBack() {
        coordinator.transitionToState(.Start)
    }
}
