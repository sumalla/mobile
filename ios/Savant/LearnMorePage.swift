//
//  LearnMorePage.swift
//  Savant
//
//  Created by Alicia Tams on 4/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class LearnMorePage : SCUPagedViewController, SystemStatusDelegate {
	
	let demoButton = SCUButton(style: SCUButtonStyle.StandardPill, title: NSLocalizedString("App Demo", comment: ""))
	let chevron = SCUButton(style: .Light, image: UIImage.sav_imageNamed("ChevronBack", tintColor: Colors.color1shade1))
	let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
	let coordinator: CoordinatorReference<SignInState>
	
	init(coordinator:CoordinatorReference<SignInState>) {
		
		self.coordinator = coordinator
		
		var colors:[UIColor] = [
			UIColor.redColor().colorWithAlphaComponent(0.4),
			UIColor.blueColor().colorWithAlphaComponent(0.4),
			UIColor.greenColor().colorWithAlphaComponent(0.4),
			UIColor.grayColor().colorWithAlphaComponent(0.4),
			UIColor.whiteColor().colorWithAlphaComponent(0.4),
			UIColor.yellowColor().colorWithAlphaComponent(0.4),
			UIColor.brownColor().colorWithAlphaComponent(0.4),
			UIColor.magentaColor().colorWithAlphaComponent(0.4),
			UIColor.purpleColor().colorWithAlphaComponent(0.4)
		]
		
		var titles:[String] = [
			"Sonos Integration",
			"Push Notifications",
			"Fan Control",
			"Camera Features",
			"Security",
			"Whole Home Scheduling",
			"Set Scenes",
			"I don't know",
			"Maybe this?",
		]
		
		var contents:[String] = [
			"Sonos supporting copy. Lorem ipsum",
			"Aliquam nec sollicitudin elit, ut suscipit quam. Morbi.",
			"Maecenas at augue in mauris.",
			"Nam id quam eros. Donec sit amet.",
			"Aenean nec vulputate elit. Nunc eget rutrum ex. Sed.",
			"Morbi nec eros turpis. Aenean semper diam et.",
			"Integer ac arcu nec purus iaculis.",
			"Mauris et aliquet neque, in ullamcorper nisl.",
			"Vestibulum at tortor lacinia, elementum.",
		]
		
		var count = 9
		
		var viewControllers = [UIViewController]()
		for i in 0...5 {
			
			var randomNumber = Int(arc4random_uniform(UInt32(count)))
			
			let controller = UIViewController()
			//controller.view.backgroundColor = colors[randomNumber]
			viewControllers.append(controller)
			
			var title = titles[randomNumber]
			var content = contents[randomNumber]
			
			titles.removeAtIndex(randomNumber)
			contents.removeAtIndex(randomNumber)
			//colors.removeAtIndex(randomNumber)
			
			var titleLabel = UILabel(frame: CGRectZero)
			var contentLabel = UILabel(frame: CGRectZero)
			
			titleLabel.font = Fonts.subHeadline2
			titleLabel.textColor = Colors.color1shade1
			titleLabel.textAlignment = .Center
			titleLabel.text = title
			
			contentLabel.font = Fonts.body
			contentLabel.textColor = Colors.color1shade1
			contentLabel.numberOfLines = 0
			contentLabel.textAlignment = .Center
			contentLabel.text = content
			
			controller.view.addSubview(titleLabel)
			controller.view.addSubview(contentLabel)
			
			controller.view.sav_pinView(titleLabel, withOptions: .CenterX)
			controller.view.sav_pinView(titleLabel, withOptions: .CenterY, withSpace:-Sizes.row * 3)
			controller.view.sav_pinView(titleLabel, withOptions: .Horizontally, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
			controller.view.sav_pinView(contentLabel, withOptions: .CenterX)
			controller.view.sav_pinView(contentLabel, withOptions: .Horizontally, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
			controller.view.sav_pinView(contentLabel, withOptions: .ToBottom, ofView: titleLabel, withSpace:Sizes.row * 2)
			
			count--
		}
		
		super.init(viewControllers: viewControllers)
		
		Savant.control().systemStatusObservers.addObject(self)
		
	}

	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)
		
		
		view.addSubview(chevron)
		chevron.target = self
		chevron.releaseAction = "goBack"
		view.sav_pinView(chevron, withOptions: .ToTop, withSpace: Sizes.row * 5)
		view.sav_pinView(chevron, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)
		
		view.addSubview(demoButton)
		demoButton.target = self
		demoButton.releaseAction = "appDemo"
		view.sav_pinView(demoButton, withOptions: .CenterX)
		view.sav_pinView(demoButton, withOptions: .ToBottom, withSpace: Sizes.row * 18)
		view.sav_setSize(buttonSize, forView: demoButton, isRelative: false)
		
		view.addSubview(spinner)
		view.sav_pinView(spinner, withOptions: .CenterX, ofView: demoButton, withSpace: 0)
		view.sav_pinView(spinner, withOptions: .CenterY, ofView: demoButton, withSpace: 0)
		spinner.hidden = true
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func appDemo() {
		demoButton.hidden = true
		spinner.hidden = false
		spinner.startAnimating()
		
		Savant.control().connectToDemoSystem()
	}
	
	func connectionDidFailToConnect() {
		demoButton.hidden = false
		spinner.stopAnimating()
		spinner.hidden = true
	}
	
	func connectionIsReady() {
		demoButton.hidden = false
		spinner.stopAnimating()
		spinner.hidden = true
		RootCoordinator.transitionToState(.Interface)
	}
	
	func goBack() {
		coordinator.transitionToState(.Landing)
	}
	
}