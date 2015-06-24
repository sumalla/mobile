//
//  StepController.swift
//  Savant
//
//  Created by Alicia Tams on 4/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class StepController : FakeNavBarViewController {
	
	let titleLabel = UILabel(frame: CGRectZero)
	let contentLabel = UILabel(frame: CGRectZero)
	var imageViews = [UIView]()
	var buttons = [SCUButton]()
	
	private let buttonsView = UIView(frame:CGRectZero)
	private let imagesView = UIView(frame:CGRectZero)
	
	init(title:String, content:String) {
		
		titleLabel.text = title
		contentLabel.text = content
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	override func loadView() {
		
		let column = Sizes.columnForOrientation(UIDevice.interfaceOrientation())
		
		view.sav_pinView(titleLabel, withOptions: .ToTop, withSpace:Sizes.row * 16)
		view.sav_pinView(titleLabel, withOptions: .ToLeft | .ToRight, withSpace:column * 4)
		view.sav_pinView(contentLabel, withOptions: .ToBottom, ofView:titleLabel, withSpace:Sizes.row * 2)
		view.sav_pinView(contentLabel, withOptions: .ToLeft | .ToRight, withSpace:column * 4)
	}
	
}