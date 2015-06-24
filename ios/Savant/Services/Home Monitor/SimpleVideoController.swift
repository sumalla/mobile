//
//  SimpleVideoController.swift
//  Savant
//
//  Created by Joseph Ross on 4/8/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class SimpleVideoController: UIViewController {
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))
    var videoView:SAVVideoView! = nil
    var dismissButton:UIButton! = nil
    
    override func viewDidLoad() {
        setupNavBar()
        
        view.addSubview(videoView)
        view.sav_addFlushConstraintsForView(videoView)
        
        dismissButton = UIButton.buttonWithType(.Custom) as! UIButton
        dismissButton.addTarget(self, action: Selector("dismissPressed:"), forControlEvents: .TouchUpInside)
        dismissButton.backgroundColor = UIColor.redColor()
        view.addSubview(dismissButton)
        
        
    }
    
    func setupNavBar() {
        
        let navBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1, Colors.color5shade1.colorWithAlphaComponent(0)])
        view.addSubview(navBar)
        view.sav_pinView(navBar, withOptions: .ToTop | .Horizontally)
        view.sav_setHeight(Sizes.row * 8, forView: navBar, isRelative: false)
        
        prompt.title.text = NSLocalizedString("ENTRYWAY", comment: "").uppercaseString
        prompt.prompt.text = NSLocalizedString("Home Monitor", comment: "").uppercaseString
        
        navBar.addSubview(prompt)
        navBar.sav_pinView(prompt, withOptions: .CenterX)
        navBar.sav_pinView(prompt, withOptions: .CenterY)
        
        let protectButton = SCUButton(style: .Light, image: UIImage(named: "ProtectToggle"))
        protectButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        protectButton.target = self;
        protectButton.releaseAction = Selector("toggleProtect")
        
        navBar.addSubview(protectButton)
        navBar.sav_pinView(protectButton, withOptions: .CenterY)
        navBar.sav_pinView(protectButton, withOptions: .ToRight, withSpace: Sizes.row * 2)
        
        let doneButton = SCUButton(style: .Light, title: "DONE")
        doneButton?.titleLabel?.font = Fonts.caption1
        doneButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        doneButton.target = self
        doneButton.releaseAction = Selector("donePressed")
        
        navBar.addSubview(doneButton)
        navBar.sav_pinView(doneButton, withOptions: .CenterY)
        navBar.sav_pinView(doneButton, withOptions: .ToLeft, withSpace: Sizes.row * 2)
    }
    
    func dismissPressed(sender:UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
