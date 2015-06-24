//
//  InternalErrorController.swift
//  Savant
//
//  Created by Alicia Tams on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class InternalErrorController: ErrorController {
	
	let coordinator:CoordinatorReference<HostOnboardingState>
	
	init(coordinator:CoordinatorReference<HostOnboardingState>) {
		
		self.coordinator = coordinator
		
		super.init(title: "Internal Error", text: "Connection failed.\nPlease try again.")
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	override func handleBack() {
		coordinator.transitionToState(.WifiPassword)
	}
}
