//
//  PagedViewController.swift
//  Savant
//
//  Created by Alicia Tams on 3/31/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import UIKit
import Extensions

class SCUPagedViewController: UIViewController, UIScrollViewDelegate {
	
	//MARK: - Properties -
	
	//enums
	private enum ScrollDirection {
		case right, left
		func description() -> String {
			switch self {
			case .right:
				return "right"
			case .left:
				return "left"
			}
		}
	}
	
	//constants
	let pagesAutomatically:Bool
	let pageTime:Float
	private let pageControl:SCUFadingPageControl
	
	//variables
	var viewControllers:[UIViewController] {
		didSet {
			setViewControllers()
		}
	}
	var currentIndex = 0
	var toIndex = 0
	
	private var scrollView:UIScrollView = UIScrollView(frame: CGRectZero)
	private var previousContentOffset:CGPoint = CGPointZero
	private var previousScrollDirection:ScrollDirection = .left
	private var shouldTrackScrolling:Bool = false
	private var percentage:CGFloat = 0.0
	private var pageTimer:NSTimer?
	
	//MARK: - Init -

	init(viewControllers:[UIViewController] = [UIViewController](), pagesAutomatically:Bool = true, pageTime:Float = 4.0) {
		
		self.pageControl = SCUFadingPageControl(numberOfPages: viewControllers.count, startPage:0, currentPageColor: UIColor.whiteColor())
		self.viewControllers = viewControllers
		self.pagesAutomatically = pagesAutomatically
		self.pageTime = pageTime
		
		super.init(nibName: nil, bundle: nil)
		
		if pagesAutomatically {
			setTimer()
		}
		
		scrollView.delegate = self
		scrollView.pagingEnabled = true
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.alwaysBounceHorizontal = true
		scrollView.alwaysBounceVertical = false
		scrollView.contentInset = UIEdgeInsetsZero
		
		self.automaticallyAdjustsScrollViewInsets = false
	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		self.view.addSubview(scrollView)
		
		scrollView.frame = view.frame
		
		self.view.addSubview(pageControl)
		
		self.view.sav_pinView(pageControl, withOptions: SAVViewPinningOptions.CenterX)
		self.view.sav_pinView(pageControl, withOptions: .ToBottom, withSpace: Sizes.row * 5)
		
		setViewControllers()
	}
	
	private func setViewControllers() {
		for (index, viewController) in enumerate(viewControllers) {
			var frame = scrollView.frame
			frame.origin.x = CGFloat(index) * scrollView.frame.size.width
			viewController.view.frame = frame
			scrollView.addSubview(viewController.view)
		}
		scrollView.contentSize = CGSizeMake(self.view.frame.size.width * CGFloat(viewControllers.count), scrollView.frame.size.height)
	}

	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		if let timer = pageTimer {
			timer.invalidate()
			pageTimer = nil
		}
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		var offset = scrollView.contentOffset.x
		var width = scrollView.frame.size.width
		var direction:ScrollDirection = offset < previousContentOffset.x ? .right : .left
		
		if (offset > 0 && offset < width * CGFloat(viewControllers.count - 1)) {
			
			shouldTrackScrolling = true
			
			currentIndex = Int(offset / width)
			var origin = CGFloat(currentIndex) * width
			var delta = fabs(origin - offset);
			percentage = delta / width
			
			toIndex = 0
			if (direction == .left) {
				toIndex = (currentIndex < viewControllers.count - 1) ? currentIndex + 1 : currentIndex
			} else {
				percentage = 1.0 - percentage
				currentIndex = currentIndex + 1
				toIndex = (currentIndex > 0) ? currentIndex - 1 : currentIndex
			}
			currentIndex = (currentIndex >= viewControllers.count - 1) ? viewControllers.count - 1 : currentIndex
			currentIndex = (currentIndex <= 0) ? 0 : currentIndex
			
			if percentage > 0.0 && percentage < 1.0 {
				//all percentage based transition logic goes here for PageViewControl
				pageControl.transition(fromIndex: currentIndex, toIndex: toIndex, percentage: percentage)
			}
			
			viewControllers[currentIndex].view.alpha = 1.0 - percentage * 0.7
			viewControllers[toIndex].view.alpha = 1.5 * percentage
		}
		
		previousContentOffset = scrollView.contentOffset
		previousScrollDirection = direction
	}
	
	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		if (shouldTrackScrolling) {
			println("\(currentIndex) to: \(toIndex) - 1.0 - \(previousScrollDirection.description())")
		}
		shouldTrackScrolling = false
	}
	
	private func setTimer() {
		pageTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(pageTime), target: self, selector: "timerTriggered", userInfo: nil, repeats: true)
	}
	
	func timerTriggered() {
		var index = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
		var tPage = (index == viewControllers.count - 1) ? 0 : index + 1
		if (tPage > 0) {
			var offset = CGFloat(tPage) * scrollView.frame.size.width
			scrollView.setContentOffset(CGPointMake(offset, 0), animated: true)
		}
	}
}
