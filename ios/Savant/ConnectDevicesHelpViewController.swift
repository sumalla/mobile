//
//  ConnectDevicesHelp.swift
//  Savant
//
//  Created by Alicia Tams on 5/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class ConnectDevicesHelpViewController: FakeNavBarViewController
{
	let coordinator: CoordinatorReference<DeviceOnboardingState>
	let card = UIView(frame: CGRectZero)
	let topLabel = UILabel(frame: CGRectZero)
	let graphicImageView = UIImageView(image: UIImage(named: "ConnectDevices"))
	let bottomLabel = UILabel(frame: CGRectZero)
	let bottomButton = SCUButton(style: .PinnedButton, title: Strings.scan.uppercaseString)
	
	var selectedRoom:SAVRoom?
	
	init(coordinator c: CoordinatorReference<DeviceOnboardingState>) {
		coordinator = c
		super.init(nibName: nil, bundle: nil)
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		bottomButton.releaseCallback =  { [weak self] in
			self?.coordinator.transitionToState(.Searching)
		}
		
		card.backgroundColor = Colors.color1shade1
		card.layer.cornerRadius = 3
		
		topLabel.numberOfLines = 0
		topLabel.font = Fonts.body
		topLabel.textColor = Colors.color3shade2
		topLabel.textAlignment = .Center
		topLabel.text = Strings.connectYourDevicesTitle
		
		bottomLabel.numberOfLines = 0
		bottomLabel.font = Fonts.caption1
		bottomLabel.textColor = Colors.color3shade2
		bottomLabel.lineBreakMode = .ByWordWrapping
		bottomLabel.textAlignment = .Center
		
		var paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = 8
		paragraphStyle.alignment = .Center
		
		var attrString = NSMutableAttributedString(string: Strings.connectYourDevicesBody)
		attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
		
		bottomLabel.attributedText = attrString
		
		view.addSubview(card)
		
		card.addSubview(topLabel)
		card.addSubview(graphicImageView)
		card.addSubview(bottomLabel)
		view.addSubview(bottomButton)
		
		view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
		view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
		card.sav_pinView(topLabel, withOptions: .CenterX)
		card.sav_pinView(graphicImageView, withOptions: .CenterX)
        card.sav_setHeight(Sizes.row * 36, forView: graphicImageView, isRelative: false)
        card.sav_setWidth(Sizes.row * 36, forView: graphicImageView, isRelative: false)
		card.sav_pinView(bottomLabel, withOptions: .CenterX)
		card.sav_setWidth(0.85, forView: bottomLabel, isRelative: true)
		
		view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
		view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
		
		setupConstraints()
	}
	
	override func padPortraitConstraints() {
		view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 30)
		view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 32)
		view.sav_pinView(card, withOptions: .CenterX)
		view.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, forView: card, isRelative: false)
	}
	
	override func padLandscapeConstraints() {
		view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 13)
		view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 17)
		view.sav_pinView(card, withOptions: .CenterX)
		view.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, forView: card, isRelative: false)
	}
	
	override func universalPadConstraints() {
		card.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
		card.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 8)
		card.sav_pinView(graphicImageView, withOptions: .ToTop, withSpace: Sizes.row * 14)
		card.sav_pinView(bottomLabel, withOptions: .ToTop, withSpace: Sizes.row * 53)
        
        card.sav_setHeight(Sizes.row * 36, forView: graphicImageView, isRelative: false)
        card.sav_setWidth(Sizes.row * 36, forView: graphicImageView, isRelative: false)
	}
	
	override func phoneConstraints() {
        card.sav_setHeight(Sizes.row * 16, forView: graphicImageView, isRelative: false)
        card.sav_setWidth(Sizes.row * 16, forView: graphicImageView, isRelative: false)
        
		view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 13)
		view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 16)
		view.sav_pinView(card, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
		
		card.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 3)
		card.sav_pinView(topLabel, withOptions: .CenterX)
		card.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
		
		card.sav_pinView(graphicImageView, withOptions: .ToTop, withSpace: Sizes.row * 10)
		card.sav_pinView(bottomLabel, withOptions: .ToTop, withSpace: Sizes.row * 26)
		
	}
	
	override func handleBack() {
		RootCoordinator.transitionToState(.Interface)
	}
}