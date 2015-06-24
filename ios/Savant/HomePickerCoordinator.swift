//
//  HomePickerCoordinator.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

func NewHomePickerCoordinator() -> CoordinatorReference<HomePickerState> {
    return Coordinator(coordinatorManager: HomePickerCoordinatorManager())
}

enum HomePickerState: Equatable, Printable {
    case Unloaded
    case HomePicker
    case UserPicker
    case Authentication(SAVLocalUser)

    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .HomePicker:
                return "HomePicker"
            case .UserPicker:
                return "UserPicker"
            case .Authentication(let user):
                return "Authentication"
            }
        }
    }
}

func ==(lhs: HomePickerState, rhs: HomePickerState) -> Bool {
    return lhs.description == rhs.description
}

class HomePickerCoordinatorManager: NSObject, CoordinatorManager, DiscoveryDelegate, UINavigationControllerDelegate {

    private override init() {}

    typealias StateType = HomePickerState

    var navigationController: UINavigationController?
    var homePicker: HomePickerCollectionViewController?
    var userPicker: HomeUserPickerTableController?
    var auth: HomeUserAuthenticationViewController?
    let crossFader = CrossFadeViewController()

    weak var coordinator: CoordinatorReference<StateType>!

    var initialState: StateType {
        get {
            return .Unloaded
        }
    }

    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (.HomePicker, .UserPicker):
            fallthrough
        case (.UserPicker, .Authentication):
            fallthrough
        case (.Authentication, .UserPicker):
            fallthrough
        case (_, .HomePicker):
            fallthrough
        case (_, .Unloaded):
            return true
        default:
            return false
        }
    }

    func transition(#fromState: StateType, toState: StateType) {
        switch toState {
        case .Unloaded:
            unload()
        case .HomePicker:
            if fromState == .Unloaded {
                load()
            } else {
                goToRoot()
            }
        case .UserPicker:
            showUserPicker()
        case .Authentication(let user):
            showAuthentication(user)
        default:
            break;
        }
    }

    private func load() {
        SCUBackgroundHandler.sharedInstance().addDelegate(self)
        Savant.discovery().addDiscoveryObserver(self)
        Savant.control().addSystemStatusObserver(self)

        RootViewController.sav_addChildViewController(crossFader)
        RootViewController.view.sav_addFlushConstraintsForView(crossFader.view)
        crossFader.image = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("whole-home", ofType: "jpg")!) // temp
        var width = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 40
        if UIDevice.isPad() {
            var width = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32
        }
        let layout = FullscreenCardFlowLayout(interspace: 15, width: 0.8, height: Sizes.row * 54)
        let hp = HomePickerCollectionViewController(collectionViewLayout: layout)
        let navController = UINavigationController(rootViewController: hp)
        hp.pickerModel = HomePickerDataModel(coordinator: coordinator)
        homePicker = hp
        
        navController.delegate = self
        navigationController = navController
        RootViewController.sav_addChildViewController(navController)
        RootViewController.view.sav_addFlushConstraintsForView(navController.view)
    }

    private func unload() {
        SCUBackgroundHandler.sharedInstance().removeDelegate(self)
        Savant.discovery().removeDiscoveryObserver(self)
        Savant.control().removeSystemStatusObserver(self)

        crossFader.sav_removeFromParentViewController()
        navigationController?.sav_removeFromParentViewController()
        navigationController = nil
        homePicker = nil
        userPicker = nil
        auth = nil
    }

    private func goToRoot() {
        Savant.control().disconnect()
        navigationController?.popToRootViewControllerAnimated(true)
        userPicker = nil
        auth = nil
    }

    private func showUserPicker() {
        if userPicker == nil {
            let up = HomeUserPickerTableController(style: .Grouped)
            up.pickerModel = HomeUserPickerDataModel(coordinator: coordinator, users: Savant.control().localUsers() as! [SAVLocalUser])
            userPicker = up
            navigationController?.pushViewController(up, animated: true)
        }
    }

    private func showAuthentication(user: SAVLocalUser) {
        let a = HomeUserAuthenticationViewController(coordinator: coordinator, user: user)
        navigationController?.pushViewController(a, animated: true)
        auth = a
    }

    // MARK: - Discovery

    func discoveryDidUpdateSystemList(discovery: SAVDiscovery) {
        if let homePicker = homePicker {
            homePicker.pickerModel.updateSystems(discovery.groupedSystems)
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if let homePicker = homePicker {
            if viewController === homePicker {
                coordinator.transitionToState(.HomePicker)
                return
            }
        }

        if let userPicker = userPicker {
            if viewController === userPicker {
                coordinator.transitionToState(.UserPicker)
                return
            }
        }
    }

}

extension HomePickerCoordinatorManager: SystemStatusDelegate {

    func connectionDidConnect() {
        if !Savant.control().demoSystem && !Savant.control().currentSystem!.cloudSystem {
            coordinator.transitionToState(.UserPicker)
            homePicker?.pickerModel?.connectionDidConnect()
        }
    }

    func connectionDidReceiveAuthChallengeForUser(user: String!) {
        let localUser = SAVLocalUser()
        localUser.accountName = user
        localUser.requiresAuthentication = Savant.control().userRequiresAuthentication(user)
        if coordinator.currentState == .Authentication(localUser) {
            auth?.handleSignInError()
        } else {
            coordinator.transitionToState(.Authentication(localUser))
        }
    }

    func connectionIsReady() {
        NSTimer.sav_scheduledBlockWithDelay(0.5) {
            RootCoordinator.transitionToState(.Interface)
        }
    }

    func connectionDidFailToConnect() {
        coordinator.transitionToState(.HomePicker)
        homePicker?.pickerModel?.connectionDidFail()
        Savant.control().disconnect()
    }
    
    func connectionDidReceiveConfigurationDownloadUpdate(progress: Float, isInstalling: Bool) {
        let realProgress = isInstalling ? CGFloat(progress / 2) + 0.5 : CGFloat(progress / 2)
        homePicker?.pickerModel?.progressDidUpdate(realProgress)
    }

}

extension HomePickerCoordinatorManager: SCUBackgroundHandlerDelegate {

    func backgroundHandlerEnterBackground() {
        Savant.control().disconnect()
        Savant.discovery().removeDiscoveryObserver(self)
    }

    func backgroundHandlerEnterForeground() {
        coordinator.transitionToState(.HomePicker)
        Savant.discovery().addDiscoveryObserver(self)
    }

}

extension HomePickerCoordinatorManager: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = ZoomOutAnimator()
        
        if toVC as? HomeUserAuthenticationViewController != nil || fromVC as? HomePickerCollectionViewController != nil {
            animator.presenting = false
        } else {
            animator.presenting = true
        }
        
        return animator
    }
    
}