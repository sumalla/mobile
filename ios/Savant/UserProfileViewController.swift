//
//  UserProfileViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 4/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class UserProfileViewController: FakeNavBarViewController {

    let imageView = UIImageView()
    let signOutButton = SCUButton(style: .Light, title: NSLocalizedString("Sign Out", comment: ""))
    let coordinator: CoordinatorReference<InterfaceState>

    init(coordinator c: CoordinatorReference<InterfaceState>) {
        coordinator = c
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .ScaleAspectFill
        imageView.image = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("whole-home", ofType: "jpg")!)
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        view.sav_addFlushConstraintsForView(imageView)

        view.addSubview(signOutButton)
        view.sav_addCenteredConstraintsForView(signOutButton)
        
        signOutButton.releaseCallback = {
            RootCoordinator.transitionToState(.SignIn)
        }
    }

    override func handleBack() {
        coordinator.transitionToState(.Rooms)
    }

}
