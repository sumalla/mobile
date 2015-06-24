//
//  OpenSettingsViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class OpenSettingsViewController: FakeNavBarViewController {
    let card = UIView(frame: CGRectZero)
    let topLabel = UILabel(frame: CGRectZero)
    let stepOneLabel = UILabel(frame: CGRectZero)
    let stepTwoLabel = UILabel(frame: CGRectZero)
    let stepThreeLabel = UILabel(frame: CGRectZero)
    let stepFourLabel = UILabel(frame: CGRectZero)
    let stepOneImageView = UIImageView(image: UIImage(named: "SwitchWifiSettings"))
    let stepTwoImageView = UIImageView(image: UIImage(named: "SwitchWifiWifi"))
    let stepThreeImageView = UIImageView(image: UIImage(named: "SwitchWifiCheck"))
    let stepFourImageView = UIImageView(image: UIImage(named: "SwitchWifiSavantIcon"))
    let settingsButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Open Settings", comment: "").uppercaseString)
    let coordinator:CoordinatorReference<HostOnboardingState>
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsButton.releaseCallback =  { [weak self] in
            let url = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = url {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        card.backgroundColor = Colors.color1shade1
        card.layer.cornerRadius = 3
        
        topLabel.numberOfLines = 0
        topLabel.font = Fonts.subHeadline2
        topLabel.textColor = Colors.color1shade1
        topLabel.textAlignment = .Center
        topLabel.text = NSLocalizedString("Switch to Your Home Wi-Fi Network", comment: "")
        
        for label in [stepOneLabel, stepTwoLabel, stepThreeLabel, stepFourLabel] {
            label.font = Fonts.caption1
            label.textColor = Colors.color3shade2
        }
        
        stepOneLabel.text = NSLocalizedString("Open settings", comment: "")
        stepTwoLabel.text = NSLocalizedString("Select Wi-Fi", comment: "")
        stepThreeLabel.text = NSLocalizedString("Choose your network", comment: "")
        stepFourLabel.text = NSLocalizedString("Come back to continue setup", comment: "")
        
        view.addSubview(topLabel)
        view.addSubview(card)

        card.addSubview(stepOneLabel)
        card.addSubview(stepTwoLabel)
        card.addSubview(stepThreeLabel)
        card.addSubview(stepFourLabel)
        card.addSubview(stepOneImageView)
        card.addSubview(stepTwoImageView)
        card.addSubview(stepThreeImageView)
        card.addSubview(stepFourImageView)
        view.addSubview(settingsButton)

        view.sav_pinView(topLabel, withOptions: .CenterX)
        view.sav_pinView(card, withOptions: .CenterX)
        
        view.sav_pinView(settingsButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: settingsButton, isRelative: false)
        
        setupConstraints()
    }
    
    override func phoneConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 34)
        view.sav_pinView(card, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
        view.sav_setHeight(Sizes.row * 23, forView: card, isRelative: false)
        
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 22)
        
        card.sav_pinView(stepOneLabel, withOptions: .ToTop, withSpace: Sizes.row * 5)
        card.sav_pinView(stepTwoLabel, withOptions: .ToTop, withSpace: Sizes.row * 9)
        card.sav_pinView(stepThreeLabel, withOptions: .ToTop, withSpace: Sizes.row * 13)
        card.sav_pinView(stepFourLabel, withOptions: .ToTop, withSpace: Sizes.row * 17)
        
        card.sav_pinView(stepOneImageView, withOptions: .CenterY, ofView: stepOneLabel, withSpace: 0)
        card.sav_pinView(stepTwoImageView, withOptions: .CenterY, ofView: stepTwoLabel, withSpace: 0)
        card.sav_pinView(stepThreeImageView, withOptions: .CenterY, ofView: stepThreeLabel, withSpace: 0)
        card.sav_pinView(stepFourImageView, withOptions: .CenterY, ofView: stepFourLabel, withSpace: 0)
        
        card.sav_pinView(stepOneImageView, withOptions: .ToLeft, ofView: stepOneLabel, withSpace: Sizes.row)
        card.sav_pinView(stepTwoImageView, withOptions: .ToLeft, ofView: stepTwoLabel, withSpace: Sizes.row)
        card.sav_pinView(stepThreeImageView, withOptions: .ToLeft, ofView: stepThreeLabel, withSpace: Sizes.row)
        card.sav_pinView(stepFourImageView, withOptions: .ToLeft, ofView: stepFourLabel, withSpace: Sizes.row)
        
        card.sav_pinView(stepOneLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 8)
        card.sav_pinView(stepTwoLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 8)
        card.sav_pinView(stepThreeLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 8)
        card.sav_pinView(stepFourLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 8)
    }
    
    override func universalPadConstraints() {
        card.sav_pinView(stepOneLabel, withOptions: .ToTop, withSpace: Sizes.row * 8)
        card.sav_pinView(stepTwoLabel, withOptions: .ToTop, withSpace: Sizes.row * 13)
        card.sav_pinView(stepThreeLabel, withOptions: .ToTop, withSpace: Sizes.row * 18)
        card.sav_pinView(stepFourLabel, withOptions: .ToTop, withSpace: Sizes.row * 23)
        
        card.sav_pinView(stepOneLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 7)
        card.sav_pinView(stepTwoLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 7)
        card.sav_pinView(stepThreeLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 7)
        card.sav_pinView(stepFourLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 7)
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 47)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32, height: Sizes.row * 32), forView: card, isRelative: false)
        
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 16)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 36)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 27)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32, height: Sizes.row * 32), forView: card, isRelative: false)
        
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 16)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 16)
    }
    
    override func handleBack() {
        self.coordinator.transitionToState(.HostFoundWifi(nil))
    }
}
