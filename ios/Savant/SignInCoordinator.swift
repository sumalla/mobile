//
//  SignInCoordinator.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

func NewSignInCoordinator() -> CoordinatorReference<SignInState> {
    return Coordinator(coordinatorManager: SignInCoordinatorManager())
}

enum SignInState: Equatable {
    case Unloaded
    case Landing
    case SignIn(email: String?, password: String?)
    case SignUpEmail(email: String?, password: String?)
    case SignUpUserProfile(email: String, password: String)
	case LearnMore

    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .Landing:
                return "Landing"
            case .SignIn:
                return "SignIn"
            case .SignUpEmail:
                return "SignUpEmail"
            case .SignUpUserProfile:
                return "SignUpUserProfile"
			case .LearnMore:
				return "LearnMore"
            }
        }
    }
}

func ==(lhs: SignInState, rhs: SignInState) -> Bool {
    return lhs.description == rhs.description
}

class SignInCoordinatorManager: NSObject, CoordinatorManager {

    private override init() {}

    typealias StateType = SignInState

    let backgroundController = ImageViewController(image: UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("LandingPage", ofType: "jpg")!)!)
    let navController = UINavigationController()

    weak var coordinator: CoordinatorReference<StateType>!

    var initialState: StateType {
        return .Unloaded
    }

    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (_, .Unloaded):
            fallthrough
        case (_, .Landing):
            fallthrough
        case (.Landing, .SignIn):
            fallthrough
        case (.Landing, .SignUpEmail):
            fallthrough
		case (.Landing, .LearnMore):
			fallthrough
        case (.SignUpEmail, .SignUpUserProfile):
            fallthrough
        case (.SignUpEmail, .SignIn):
            fallthrough
        case (.SignUpUserProfile, .SignUpEmail):
            return true
        default:
            return false
        }
    }

    func transition(#fromState: StateType, toState: StateType) {
        switch (fromState, toState) {
        case (_, .Unloaded):
            unload()
        case (.Unloaded, .Landing):
            load()
        case (_, .Landing):
            navController.popToRootViewControllerAnimated(true)
        case (.Landing, .SignIn):
            signIn(email: nil, password: nil)
        case (.Landing, .SignUpEmail):
            signUpEmail()
		case (.Landing, .LearnMore):
			learnMore()
        case (.SignUpEmail, .SignIn(let email, let password)):
            signIn(email: email, password: password)
        case (.SignUpEmail, .SignUpUserProfile(let email, let password)):
            signUpUserProfile(email: email, password: password)
        case (.SignUpUserProfile, .SignUpEmail):
            navController.popViewControllerAnimated(true)
        default:
            break
        }
    }

    private func load() {
        navController.delegate = self
        RootViewController.sav_addChildViewController(backgroundController)
        RootViewController.view.sav_addFlushConstraintsForView(backgroundController.view)
        let landingPage = LandingPage(coordinator: coordinator)
        navController.pushViewController(landingPage, animated: false)
        RootViewController.sav_addChildViewController(navController)
    }

    private func unload() {
        backgroundController.sav_removeFromParentViewController()
        navController.sav_removeFromParentViewController()
    }

    private func signIn(#email: String?, password: String?) {
        let signInPage = SignInPage(coordinator: coordinator, email: email, password: password)
        navController.pushViewController(signInPage, animated: true)
    }

    private func signUpEmail() {
        let signUpEmailpage = SignUpEmailPage(coordinator: coordinator)
        navController.pushViewController(signUpEmailpage, animated: true)
    }

    private func signUpUserProfile(#email: String, password: String) {
        let signUpUserProfilePage = SignUpUserProfilePage(coordinator: coordinator, email: email, password: password)
        navController.pushViewController(signUpUserProfilePage, animated: true)
    }
	
	private func learnMore() {
		let learnMorePage = LearnMorePage(coordinator: coordinator)
		navController.pushViewController(learnMorePage, animated: true)
	}
    
}

extension SignInCoordinatorManager: UINavigationControllerDelegate {

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        let animator = ZoomOutAnimator(toAlpha: 0.0)
        if toVC as? LandingPage != nil {
            animator.presenting = true
        } else if toVC as? SignUpUserProfilePage != nil && fromVC as? SignUpEmailPage != nil {
            let animator = SlideAnimator()
            animator.fromDirection = .Right
            return animator
        } else if toVC as? SignUpEmailPage != nil && fromVC as? SignUpUserProfilePage != nil {
            let animator = SlideAnimator()
            animator.fromDirection = .Left
            return animator
        } else {
            animator.presenting = false
        }
        
        return animator
    }
}
