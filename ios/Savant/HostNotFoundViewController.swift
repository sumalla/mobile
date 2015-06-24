//
//  HostNotFoundViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

class HostNotFoundViewController: TipCollectionViewController {
    let rescanButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Re-scan", comment: ""))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(rescanButton)
        view.sav_pinView(rescanButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: rescanButton, isRelative: false)
        
        rescanButton.releaseCallback = { [weak self] in
            self?.coordinator.transitionToState(.Searching)
        }
        
        setupConstraints()
    }
    
    override func universalPadConstraints() {
        
    }
    
    override func padPortraitConstraints() {
        self.collectionView?.frame.origin.y = Sizes.row * 32
        self.collectionView?.frame.size.height = Sizes.row * 64
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 105)
        
    }
    
    override func padLandscapeConstraints() {
        self.collectionView?.frame.origin.y = Sizes.row * 16
        self.collectionView?.frame.size.height = Sizes.row * 62
//        self.collectionView?.frame.size.width = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 9)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 81)
    }
    
    override func phoneConstraints() {
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 27)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 58)
    }
    

    override func handleHelpButton() {
        coordinator.transitionToState(.Searching)
    }
    
    override func handleBack() {
        coordinator.transitionToState(.Start)
    }
}
