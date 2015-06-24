//
//  SCUFadingPageControl.swift
//  Savant
//
//  Created by Alicia Tams on 4/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class SCUFadingPageControl:UIView {
	
	var views = [UIView]()
	private var currentPageColor:UIColor
	
	init(numberOfPages:Int, startPage:Int, borderColor:UIColor = UIColor.whiteColor(), currentPageColor:UIColor = UIColor.whiteColor()) {
		
		self.currentPageColor = currentPageColor
		
		super.init(frame: CGRectZero)
		
		for i in 0...numberOfPages - 1 {
			var view = UIView(frame: CGRectZero)
			view.layer.masksToBounds = true
			view.layer.borderColor = borderColor.CGColor
			view.layer.borderWidth = 1.0
			view.cornerRadius = Sizes.row / 2
			view.backgroundColor = currentPageColor.colorWithAlphaComponent((i == startPage) ? 1.0 : 0.0)
			self.addSubview(view)
			views.append(view)
		}
		
		var config = SAVViewDistributionConfiguration()
		config.interSpace = Sizes.row / 2
		config.fixedHeight = Sizes.row
		config.fixedWidth = Sizes.row
		
		self.sav_distributeViewsEvenly(views, withConfiguration: config)
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func transition(#fromIndex:Int, toIndex:Int, percentage:CGFloat) {
		views[fromIndex].backgroundColor = currentPageColor.colorWithAlphaComponent(1.0 - percentage)
		views[toIndex].backgroundColor = currentPageColor.colorWithAlphaComponent(percentage)
	}
	
}