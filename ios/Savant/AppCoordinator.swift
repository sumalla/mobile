//
//  AppCoordinator.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//


import UIKit
import Coordinator

func NewAppCoordinator() -> CoordinatorReference<AppState> {
    return Coordinator(coordinatorManager: AppCoordinatorManager())
}

enum AppState: Equatable, Printable {
    case Unloaded
    case SignIn
    case Interface
    case HomePicker
    case HostOnboarding
    case DeviceOnboarding

    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .SignIn:
                return "SignIn"
            case .HomePicker:
                return "HomePicker"
            case .Interface:
                return "Interface"
            case .HostOnboarding:
                return "HostOnboarding"
            case .DeviceOnboarding:
                return "DeviceOnboarding"
            }
        }
    }
}

var signInCoordinator: CoordinatorReference<SignInState>?
var hostOnboardingCoordinator: CoordinatorReference<HostOnboardingState>?
var deviceOnboardingCoordinator: CoordinatorReference<DeviceOnboardingState>?
var homePickerCoordinator: CoordinatorReference<HomePickerState>?
var interfaceCoordinator: CoordinatorReference<InterfaceState>?

class AppCoordinatorManager: NSObject, CoordinatorManager {

    private override init() {}

    typealias StateType = AppState

    weak var coordinator: CoordinatorReference<StateType>!

    var initialState: StateType {
        get {
            return .Unloaded
        }
    }

    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (_, .SignIn):
            fallthrough
        case (_, .HomePicker):
            fallthrough
        case (_, .Interface):
            fallthrough
        case (.SignIn, .HostOnboarding):
            fallthrough
        case (.HomePicker, .HostOnboarding):
            fallthrough
		case (.Interface, .DeviceOnboarding):
			fallthrough
        case (.HostOnboarding, .DeviceOnboarding):
            fallthrough
		case (.HostOnboarding, .HomePicker):
			fallthrough
		case (.DeviceOnboarding, .Interface):
			return true
        default:
            return false
        }
    }

    func transition(#fromState: StateType, toState: StateType) {
        switch toState {
        case .SignIn:
            Savant.control().signOut()
            Savant.control().disconnect()
            unloadInterface()
            unloadHomePicker()

            let si = NewSignInCoordinator()
            si.transitionToState(.Landing)
            signInCoordinator = si
        case .HomePicker:
            unloadSignIn()
            unloadInterface()

            Savant.control().disconnect()
            let hpc = NewHomePickerCoordinator()
            hpc.transitionToState(.HomePicker)
            homePickerCoordinator = hpc
        case .Interface:
            unloadHomePicker()
            unloadSignIn()
			unloadDeviceOnboarding()
            let ic = NewInterfaceCoordinator()
            ic.transitionToState(.House)
            interfaceCoordinator = ic
        case .HostOnboarding:
            unloadHomePicker()
            unloadSignIn()
            let ho = NewHostOnboardingCoordinator()
            ho.transitionToState(.Start)
            hostOnboardingCoordinator = ho
        case .DeviceOnboarding:
            unloadHostOnboarding()
			unloadInterface()
            let dc = NewDeviceOnboardingCoordinator()
            dc.transitionToState(.ConnectDevices)
            deviceOnboardingCoordinator = dc
        default:
            break
        }
    }

    private func unloadSignIn() {
        if let si = signInCoordinator {
            si.transitionToState(.Unloaded)
            si.unload()
            signInCoordinator = nil
        }
    }

    private func unloadHomePicker() {
        if let hpc = homePickerCoordinator {
            hpc.transitionToState(.Unloaded)
            hpc.unload()
            homePickerCoordinator = nil
        }
    }

    private func unloadInterface() {
        if let ic = interfaceCoordinator {
            ic.transitionToState(.Unloaded)
            ic.unload()
            interfaceCoordinator = nil
        }
    }
    
    private func unloadHostOnboarding() {
        if let oc = hostOnboardingCoordinator {
            oc.transitionToState(.Unloaded)
            hostOnboardingCoordinator = nil
        }
    }
    
    private func unloadDeviceOnboarding() {
        if let dc = deviceOnboardingCoordinator {
            dc.transitionToState(.Unloaded)
            deviceOnboardingCoordinator = nil
        }
    }

}
