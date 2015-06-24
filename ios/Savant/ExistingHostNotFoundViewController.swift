//
//  ExistingHostNotFoundViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

class ExistingHostNotFoundViewController: TipCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConstraints()
    }
    
    override func universalPadConstraints() {
        
    }
    
    override func padPortraitConstraints() {
        self.collectionView?.frame.origin.y = Sizes.row * 32
        self.collectionView?.frame.size.height = Sizes.row * 100

        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 105)
        
    }
    
    override func padLandscapeConstraints() {
        self.collectionView?.frame.origin.y = Sizes.row * 32
        self.collectionView?.frame.size.height = Sizes.row * 100
        
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 81)
        
    }
    
    override func phoneConstraints() {
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        view.sav_pinView(bottomButton, withOptions: .ToTop, withSpace: Sizes.row * 58)
    }
    
    override func handleHelpButton() {
        //coordinator.transitionToState(.Start)
    }
    
    override func handleBack() {
        coordinator.transitionToState(.Start)
    }
}
