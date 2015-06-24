//
//  OnboardingViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/30/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import Extensions

class OnboardingViewController: FakeNavBarViewController {
    let coordinator:CoordinatorReference<HostOnboardingState>
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

