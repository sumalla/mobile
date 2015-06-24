//
//  ViewController.swift
//  Savant
//
//  Created by Stephen Silber on 5/1/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Extensions

class ViewController: UIViewController {
    var currentConstraints = Set<NSLayoutConstraint>()

    func setupConstraints() {
        setupConstraints(UIDevice.interfaceOrientation())
        
        if UIDevice.isPad() {
            universalPadConstraints()
        }
    }
    
    func setupConstraints(orientation: UIInterfaceOrientation) {
        if currentConstraints.count > 0 {
            view.removeConstraints(Array(currentConstraints))
        }
        
        let beforeConstraints = Set(view.constraints() as! [NSLayoutConstraint])
        
        if UIDevice.isPad() {
            if orientation == .Portrait || orientation == .PortraitUpsideDown {
                padPortraitConstraints()
            } else {
                padLandscapeConstraints()
            }
        } else {
            phoneConstraints()
        }
        
        let afterConstraints = Set(view.constraints() as! [NSLayoutConstraint])
        currentConstraints = afterConstraints.subtract(beforeConstraints)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.animateInterfaceRotationChangeWithCoordinator(coordinator, block: { (orientation: UIInterfaceOrientation) -> Void in
            self.setupConstraints(orientation)
        })
    }
    
    func universalPadConstraints() {
        
    }
   
    func padPortraitConstraints() {

    }
    
    func padLandscapeConstraints() {

    }
    
    func phoneConstraints() {

    }
}
