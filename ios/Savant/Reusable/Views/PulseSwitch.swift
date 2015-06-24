//
//  PulseSwitch.swift
//  Savant
//
//  Created by Alicia Tams on 5/19/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Extensions

enum PulseSwitchAnimationType {
	case Pulse
	case Slam
}

@objc protocol PulseSwitchDelegate {
	func PulseSwitchToggled(sender: PulseSwitch)
}

class PulseSwitch: UIView {
	
	var pulseScale:CGFloat = 1.25
	var on: Bool = false
	var color = Colors.color1shade1
	var animationType:PulseSwitchAnimationType = .Pulse
	
	var listenToTouches:Bool = true {
		didSet {
			if listenToTouches {
				self.addGestureRecognizer(self.tapGestureRecognizer!)
			} else {
				self.removeGestureRecognizer(self.tapGestureRecognizer!)
			}
		}
	}
	
	let rightView = UIView(frame: CGRectZero)
	let leftView = UIView(frame: CGRectZero)
	
	internal var callback: ((on:Bool) -> Void)?
	
	var tapGestureRecognizer:UITapGestureRecognizer?
	
	override init(frame:CGRect) {
		
		super.init(frame: CGRectMake(0, 0, 20, 20))
		
		borderWidth = 1
		borderColor = color
		clipsToBounds = true
		self.layer.cornerRadius = self.frame.size.width / 2
		
		let views = [leftView, rightView]
		for view in views {
			view.backgroundColor = color
			addSubview(view)
		}
		
		leftView.frame = CGRectMake(-20, 0, 20, 20)
		rightView.frame = CGRectMake(20, 0, 20, 20)
		
		tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "toggle")
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setOn(on: Bool, animated: Bool) {
		self.on = on
		
		if (animated) {
			switch(animationType) {
			case .Pulse:
				pulse(on)
			case .Slam:
				fallthrough
			default:
				slam(on)
			}
		}
		else {
			self.backgroundColor = color.colorWithAlphaComponent(CGFloat(on))
		}
		
		if let call = callback {
			call(on: on)
		}
	}
	
	private func pulse(on:Bool) {
		UIView.animateWithDuration(0.2, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut,
			animations: { () -> Void in
				if (on) {
					self.transform = CGAffineTransformMakeScale(self.pulseScale, self.pulseScale)
				} else {
					self.transform = CGAffineTransformMakeScale(1.0 - (self.pulseScale - 1.0), 1.0 - (self.pulseScale - 1.0))
				}
				
			}, completion: { (complete) -> Void in
				UIView.animateWithDuration(0.3, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut, animations: { () -> Void in
					self.transform = CGAffineTransformMakeScale(1.0, 1.0)
					}, completion: nil)
		})
		
		UIView.animateWithDuration(0.4, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut,
			animations: { () -> Void in
				if (on) {
					self.backgroundColor = self.color.colorWithAlphaComponent(1.0)
				} else {
					self.backgroundColor = self.color.colorWithAlphaComponent(0.0)
				}
			}, completion: nil)

	}
	
	private func slam(on:Bool) {
		
		UIView .animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.3, options: .BeginFromCurrentState | .CurveEaseIn,
			animations: { () -> Void in
			if (on) {
				self.leftView.alpha = 1.0
				self.rightView.alpha = 1.0
				self.leftView.transform = CGAffineTransformMakeTranslation(10, 0)
				self.rightView.transform = CGAffineTransformMakeTranslation(-10, 0)
			} else {
				self.leftView.alpha = 1.0
				self.rightView.alpha = 1.0
				self.leftView.transform = CGAffineTransformMakeTranslation(-10, 0)
				self.rightView.transform = CGAffineTransformMakeTranslation(10, 0)
			}
		}, completion: nil)
	}
	
	internal func toggle() {
		setOn(on ? false : true, animated: true)
	}
}