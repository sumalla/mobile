//
//  LandingPage.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class LandingPage: UIViewController, DiscoveryDelegate {

    let savantLogo = UIImageView(image: UIImage.sav_imageNamed("SavantLogo", tintColor: Colors.color1shade1))
    let signInButton = SCUButton(style: .StandardPill, title: Strings.signIn)
    let createAccountButton = SCUButton(style: .StandardPill, title: Strings.createAccount)
    let learnMoreButton = SCUButton(style: .Light, attributedTitle: NSAttributedString.sav_underlinedAttributedStringWithString(Strings.learnMoreAboutSavant))
    let localSystemsButton = SCUButton(style: .Light)
    let coordinator: CoordinatorReference<SignInState>
    var learnMoreCenteredContraint: NSLayoutConstraint?

    init(coordinator c: CoordinatorReference<SignInState>) {
        coordinator = c
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(savantLogo)
        view.sav_pinView(savantLogo, withOptions: .CenterX)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 7), forView: savantLogo, isRelative: false)
        savantLogo.contentMode = .ScaleAspectFill

        if UIDevice.isPad() {
            view.sav_pinView(savantLogo, withOptions: .ToTop, withSpace: Sizes.row * 30)
        } else if UIDevice.isShortPhone() {
            view.sav_pinView(savantLogo, withOptions: .ToTop, withSpace: Sizes.row * 18)
        } else {
            view.sav_pinView(savantLogo, withOptions: .ToTop, withSpace: Sizes.row * 26)
        }

        learnMoreButton.titleLabel?.font = Fonts.caption1
        view.addSubview(learnMoreButton)
        let centeredConstraint = NSLayoutConstraint(item: learnMoreButton, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
        view.addConstraint(centeredConstraint)
        learnMoreCenteredContraint = centeredConstraint
        view.sav_pinView(learnMoreButton, withOptions: .ToBottom, withSpace: Sizes.row * 4)
        view.sav_setHeight(Sizes.row * 3, forView: learnMoreButton, isRelative: false)
		learnMoreButton.target = self
		learnMoreButton.releaseAction = "learnMore"

        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)

        createAccountButton.target = self
        createAccountButton.releaseAction = "signUp"
        view.addSubview(createAccountButton)
        view.sav_pinView(createAccountButton, withOptions: .CenterX)
        view.sav_pinView(createAccountButton, withOptions: .ToTop, ofView: learnMoreButton, withSpace: Sizes.row * 4)
        view.sav_setSize(buttonSize, forView: createAccountButton, isRelative: false)

        signInButton.target = self
        signInButton.releaseAction = "signIn"
        view.addSubview(signInButton)
        view.sav_pinView(signInButton, withOptions: .CenterX)
        view.sav_pinView(signInButton, withOptions: .ToTop, ofView: createAccountButton, withSpace: Sizes.row * 2)
        view.sav_setSize(buttonSize, forView: signInButton, isRelative: false)

        view.addSubview(localSystemsButton)
        localSystemsButton.titleLabel?.font = Fonts.caption1
        localSystemsButton.alpha = 0
        localSystemsButton.target = self
        localSystemsButton.releaseAction = "skipSignIn"
        view.sav_pinView(localSystemsButton, withOptions: .ToRight, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
        view.sav_pinView(localSystemsButton, withOptions: .ToBottom, withSpace: Sizes.row * 4)
        view.sav_setHeight(Sizes.row * 3, forView: localSystemsButton, isRelative: false)
    }

    func signIn() {
        coordinator.transitionToState(.SignIn(email: nil, password: nil))
    }

    func signUp() {
        coordinator.transitionToState(.SignUpEmail(email: nil, password: nil))
    }
	
	func learnMore() {
		coordinator.transitionToState(.LearnMore)
	}

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Savant.discovery().addDiscoveryObserver(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Savant.discovery().removeDiscoveryObserver(self)
    }

    func discoveryDidUpdateSystemList(discovery: SAVDiscovery!) {
        var count = 0

        if let localSystems = discovery.groupedSystems[SAVDiscoveryLocalSystemsKey] as? [SAVSystem] {
            count = localSystems.count
        }

        showLocalSystemsButtonIfNecessary(count)
    }

    private func showLocalSystemsButtonIfNecessary(systemCount: Int) {
        if learnMoreCenteredContraint != nil && systemCount == 0 {
            return
        }

        let string = Strings.hostsFound(systemCount)

        localSystemsButton.attributedTitle = NSAttributedString.sav_underlinedAttributedStringWithString(string)

        if let centeredConstraint = learnMoreCenteredContraint {
            view.layoutIfNeeded()

            view.removeConstraint(centeredConstraint)

            view.sav_pinView(learnMoreButton, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)

            UIView.animateWithDuration(0.35) {
                self.view.layoutIfNeeded()
                self.localSystemsButton.alpha = 1
            }

            learnMoreCenteredContraint = nil
        }
    }

    func skipSignIn() {
        RootCoordinator.transitionToState(.HomePicker)
    }

}
