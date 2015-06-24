//
//  StartPage.swift
//  Savant
//
//  Created by Alicia Tams on 4/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class StartPage : OnboardingViewController, SAVReachabilityDelegate {
    
    let imageView = UIImageView(image: UIImage(named: "SmartHost")?.tintedImageWithColor(Colors.color1shade1))
    let topLabel = UILabel(frame: CGRectZero)
    let detailLabel = UILabel(frame: CGRectZero)
    let beginButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Next", comment: "").uppercaseString)
    let existingSystemButton = SCUButton(style: .UnderlinedText, title: NSLocalizedString("I already have a Savant System", comment: ""))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topLabel.font = Fonts.subHeadline3
        topLabel.textColor = Colors.color1shade1
        topLabel.text = NSLocalizedString("Let's Get Started", comment: "")

        detailLabel.font = Fonts.body
        detailLabel.textColor = Colors.color1shade1
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .Center
        detailLabel.text = NSLocalizedString("It's time to set up your Savant Home.", comment: "")

        beginButton.releaseCallback =  { [weak self] in
            self?.coordinator.transitionToState(.EnableBTLEWifi)
        }
        
        existingSystemButton.releaseCallback =  { [weak self] in
            //self?.coordinator.transitionToState(.ExistingHostNotFound)
//			RootCoordinator.transitionToState(.HomePicker)
            RootCoordinator.transitionToState(.DeviceOnboarding)
        }
        
        view.addSubview(imageView)
        view.addSubview(topLabel)
        view.addSubview(detailLabel)
        view.addSubview(existingSystemButton)
        view.addSubview(beginButton)
        
        view.sav_pinView(beginButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: beginButton, isRelative: false)
        
        view.sav_pinView(imageView, withOptions: .CenterX)
        view.sav_pinView(topLabel, withOptions: .CenterX)
        view.sav_pinView(detailLabel, withOptions: .CenterX)
        view.sav_pinView(existingSystemButton, withOptions: .CenterX)
        
        setupConstraints()
    }
	
    override func padLandscapeConstraints() {
        view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 22)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 45)
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 52)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
        view.sav_pinView(existingSystemButton, withOptions: .ToTop, withSpace: Sizes.row * 58)

    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 34)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 60)
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 67)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
        view.sav_pinView(existingSystemButton, withOptions: .ToTop, withSpace: Sizes.row * 73)
    }

    override func phoneConstraints() {
        view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 20)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 36)
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 42)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
        view.sav_pinView(existingSystemButton, withOptions: .ToTop, withSpace: Sizes.row * 50)
    }
		
	override func handleBack() {
		RootCoordinator.transitionToState(.HomePicker)
	}
	
}