//
//  ErrorController.swift
//  Savant
//
//  Created by Alicia Tams on 5/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class ErrorController: FakeNavBarViewController {
	
	let imageView = UIImageView(image: UIImage(named: "Plus")?.tintedImageWithColor(Colors.color1shade1))
	let topLabel = UILabel(frame: CGRectZero)
	let detailLabel = UILabel(frame: CGRectZero)
	let retryButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Retry", comment: "").uppercaseString)
	
	var retryClosure: (() -> Void)?
	
	init(
		title: String? = NSLocalizedString("Error", comment: ""),
		text: String? = NSLocalizedString("An error has occured", comment: ""),
		retryClosure: (() -> Void)? = nil)
	{
		topLabel.font = Fonts.subHeadline3
		topLabel.textColor = Colors.color1shade1
		topLabel.text = title
		
		detailLabel.font = Fonts.body
		detailLabel.textColor = Colors.color1shade1
		detailLabel.numberOfLines = 0
		detailLabel.textAlignment = .Center
		detailLabel.text = text
		
		self.retryClosure = retryClosure
		
		super.init(nibName: nil, bundle: nil)
		
		retryButton.target = self
		retryButton.releaseAction = "retryReleased"
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		view.addSubview(imageView)
		view.addSubview(topLabel)
		view.addSubview(detailLabel)
		view.addSubview(retryButton)
		
		view.sav_pinView(retryButton, withOptions: .Horizontally | .ToBottom)
		view.sav_setHeight(Sizes.row * 9, forView: retryButton, isRelative: false)
		view.sav_pinView(imageView, withOptions: .CenterX)
		view.sav_pinView(topLabel, withOptions: .CenterX)
		view.sav_pinView(detailLabel, withOptions: .CenterX)
		
		setupConstraints()
	}
	
	override func loadView() {
		super.loadView()
	}
	
	override func padLandscapeConstraints() {
		view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 22)
		view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 45)
		view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 52)
		view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
	}
	
	override func padPortraitConstraints() {
		view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 22)
		view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 45)
		view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 52)
		view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
	}
	
	override func phoneConstraints() {
		view.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 20)
		view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 36)
		view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 42)
		view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
	}
	
	internal func retryReleased() {
		if let retry = retryClosure {
			retry()
		}
	}
}