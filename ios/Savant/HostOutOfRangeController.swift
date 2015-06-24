//
//  HostOutOfRangeController.swift
//  Savant
//
//  Created by Alicia Tams on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class HostOutOfRangeController: ErrorController {
	
	let coordinator:CoordinatorReference<HostOnboardingState>
	
	init(coordinator:CoordinatorReference<HostOnboardingState>) {
		
		self.coordinator = coordinator
		
		super.init(title: "Host Out of Range", text: "Oops your host is out of range of you Wi-Fi network. Make sure your host is in an area with a stronger Wi-Fi signal.")
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func handleBack() {
		coordinator.transitionToState(.WifiPassword)
	}
}
