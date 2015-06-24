//
//  ErrorBadPasswordController.swift
//  Savant
//
//  Created by Alicia Tams on 5/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class BadWifiPasswordController: ErrorController {
	
	let coordinator:CoordinatorReference<HostOnboardingState>
	
	init(coordinator:CoordinatorReference<HostOnboardingState>) {
		
		self.coordinator = coordinator
		
		super.init(title: "Host Set-up Error", text: "Oops you entered the wrong password to your Wi-Fi network")
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func handleBack() {
		coordinator.transitionToState(.WifiPassword)
	}
}