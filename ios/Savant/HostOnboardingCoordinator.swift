//
//  HostOnboardingCoordinator.swift
//  Savant
//
//  Created by Julian Locke on 4/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

func NewHostOnboardingCoordinator() -> CoordinatorReference<HostOnboardingState> {
    return Coordinator(coordinatorManager: HostOnboardingCoordinatorManager())
}

enum HostOnboardingState: Equatable {
    case Unloaded
    case Start
    case PlugInHost
    case Searching
    case HostFound
    case HostsFound
    case HostFoundWifi(ProvisionableDevice?)
    case HostNotFound
    case EnableBTLEWifi
    case SwitchWifi
    case WifiPassword
    case NoWifiPassword
    case CheckWifiCredentials(String)
    case Provisioning
    case ProvisioningError(Int)
    case ProvisioningSuccess
    case AddHome
    case AddDevices
    case Rooms
    case AddRoom
    case ExistingHostNotFound
    case NewHostNotFound
    case HomeNaming
	case ErrorInternal
	case ErrorBadPassword
	case ErrorRange
    
    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .Start:
                return "Start"
            case .PlugInHost:
                return "PlugInHost"
            case .EnableBTLEWifi:
                return "BTLEWifi"
            case .Provisioning:
                return "Provisioning"
            case .Rooms:
                return "Rooms"
            case .AddRoom:
                return "Add Room"
            case .HostNotFound:
                return "HostNotFound"
            case .SwitchWifi:
                return "SwitchWifi"
            case .HostFound:
                return "HostFound"
            case .HostsFound:
                return "HostsFound"
            case .HostFoundWifi(let host):
                return "HostFoundWifi"
            case .WifiPassword:
                return "WifiPassword"
            case .NoWifiPassword:
                return "NoWifiPassword"
            case .CheckWifiCredentials(let password):
                return "CheckWifiCredentials"
            case .Searching:
                return "Searching"
            case .Provisioning:
                return "Provisioning"
            case .ProvisioningError(let error):
                return "ProvisioningError"
            case .ProvisioningSuccess:
                return "ProvisioningSuccess"
            case .ExistingHostNotFound:
                return "ExistingHostNotFound"
            case .NewHostNotFound:
                return "NewHostNotFound"
            case .HomeNaming:
                return "HomeNaming"
			case .ErrorBadPassword:
				return "ErrorBadPassword"
			case .ErrorInternal:
				return "ErrorInternal"
			case .ErrorRange:
				return "ErrorRange"
				
             default:
                return "Implement"
            }
        }
    }
}

func ==(lhs: HostOnboardingState, rhs: HostOnboardingState) -> Bool {
    return lhs.description == rhs.description
}

class HostOnboardingCoordinatorManager: NSObject, CoordinatorManager, UINavigationControllerDelegate, SAVReachabilityDelegate, SAVProvisionerDelegate, DiscoveryDelegate {
    
    private override init() {}
    
    typealias StateType = HostOnboardingState
    var currentHost: ProvisionableDevice?
    var currentHosts = [ProvisionableDevice]()
    var wifiCredentials = WifiCredentials()
    
    var pulseViewController: PulsingViewController?
    var hostsFoundModel: HostsFoundCollectionViewModel?
    let backgroundController = ImageViewController(image: UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("LandingPage", ofType: "jpg")!)!)
    let navController = UINavigationController()
    var searchTimer = NSTimer()
    weak var coordinator: CoordinatorReference<StateType>!
    
    var initialState: StateType {
        return .Unloaded
    }
    
    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (_, .Unloaded):
            fallthrough
        //Implement
        case (_,_):
            return true
        default:
            return false
        }
    }
    
    func transition(#fromState: StateType, toState: StateType) {
        println("FROM: \(fromState.description) - TO: \(toState.description)")
        switch (fromState, toState) {
        case (_, .Unloaded):
            unload()
        case (.Unloaded, .Start):
            load()
            
            // Let's Get Started Page
        case (.Start, .EnableBTLEWifi):
            showBTLEWifi()
        case (.Start, .PlugInHost):
            showPlugInHost()
        case (.Start, .HostFound):
            showHostFound()
        case (.Start, .HostsFound):
            showHostsFound()
        case (.Start, .ExistingHostNotFound):
            showExistingHostNotFound()
            
        case (.ExistingHostNotFound, .Start):
            showStartPage()
            
            // Enable Bluetooth / Wifi Radio Page
        case (_, .EnableBTLEWifi):
            showBTLEWifi()
        case (.EnableBTLEWifi, .Start):
            showStartPage()
        case (.EnableBTLEWifi, .PlugInHost):
            showPlugInHost()
        case (.EnableBTLEWifi, .Searching):
            showSearching()
        case (.EnableBTLEWifi, .HostFoundWifi(let host)):
            showHostFoundWifi(currentHost!)
        case (.EnableBTLEWifi, .WifiPassword):
            showWifiPassword()
        case (.EnableBTLEWifi, .NoWifiPassword):
            showNoWifiPassword()
        case (.EnableBTLEWifi, .SwitchWifi):
            showSwitchWifi()
        case (.EnableBTLEWifi, .HostsFound):
            showHostsFound()
        case (.EnableBTLEWifi, .HostFound):
            showPlugInHost()
        case (.EnableBTLEWifi, .HostNotFound):
            showHostNotFound()
            
            // Plug In Your Host page
        case (.PlugInHost, .Searching):
            showSearching()
        case (.PlugInHost, .Start): //BACK
            showStartPage()
        case (.PlugInHost, .HostsFound):
            showHostsFound()
        case (.PlugInHost, .HostFound):
            showHostFound()
            
            // Searching page
        case (.Searching, .HostsFound):
            showHostsFound()
        case (.Searching, .HostFound):
            showHostFound()
        case (.Searching, .HostNotFound):
            showHostNotFound()
        case (.Searching, .Start): //BACK
            searchTimer.invalidate()
            showStartPage()
        case (_, .Searching):
            showSearching()
            
            // Hosts Found page
        case (.HostsFound, .HostFoundWifi(let host)):
            showHostFoundWifi(host!) // SRS: Hack
        case (.HostsFound, .Start): //BACK
            showStartPage()
            
            // Host Found page
        case (.HostFound, .HostFoundWifi(let host)):
            showHostFoundWifi(currentHost!)
        case (.HostFound, .HostsFound):
            showHostsFound()
        case (.HostFound, .Start): //BACK
            showStartPage()
            
            // Host Not Found page
        case (.HostNotFound, .NewHostNotFound):
            showHostNotFound()
        case (.HostNotFound, .Searching):
            showSearching()
        case (.HostNotFound, .Start): //BACK
            showStartPage()
            
            // Host Found Wifi
        case (.HostFoundWifi, .WifiPassword):
            showWifiPassword()
        case (.HostFoundWifi, .SwitchWifi):
            showSwitchWifi()
        case (.HostFoundWifi(let host), .HostFound): //BACK
            showHostFound()
        case (.HostFoundWifi(let host), .HostsFound): //BACK
            showHostsFound()
        case (.HostFoundWifi(let host), .PlugInHost): //BACK
            showPlugInHost()
            
            
            // Switch Wifi page
        case (.SwitchWifi, .HostFoundWifi(let host)): //BACK
            showHostFoundWifi(currentHost!)
            
            // Wifi Password page
        case (.WifiPassword, .NoWifiPassword):
            showNoWifiPassword()
        case (.WifiPassword, .CheckWifiCredentials(let password)):
            wifiCredentials.presharedKey = password
            coordinator.transitionToState(.Provisioning)
        case (.WifiPassword, .Provisioning):
            showProvisioning()
        case (.WifiPassword, .HostFoundWifi): //BACK
            showHostFoundWifi(currentHost!)
        case (.WifiPassword, .Start): //BACK
            showStartPage()

            // No Wifi Password page
        case (.NoWifiPassword, .CheckWifiCredentials(let password)):
            wifiCredentials.presharedKey = password
            coordinator.transitionToState(.Provisioning)
        case (.NoWifiPassword, .WifiPassword): //BACK
            showWifiPassword()
            
        case (.CheckWifiCredentials(let password), .Provisioning):
            showProvisioning()
            
            // Provisioning
        case (.Provisioning, .ProvisioningSuccess):
            showProvisioningSuccess()
        case (.Provisioning, .ProvisioningError(let error)):
            showProvisioningError(error)
        case (.Provisioning, .Start): //BACK
            showStartPage()
            
        case (.ProvisioningSuccess, .Start):
            showStartPage()

            //Errors
        case (.ProvisioningError(let error), .ErrorInternal):
            showInternalError()
        case (.ProvisioningError(let error), .ErrorBadPassword):
            showBadWifiPassword()
        case (.ProvisioningError(let error), .ErrorRange):
            showHostOutOfRange()
            
        case (.ErrorInternal, .Searching):
            showSearching()
        case (.ErrorInternal, .Provisioning):
            showProvisioning()
        case (.ErrorBadPassword, .Searching):
            showSearching()
        case (.ErrorBadPassword, .WifiPassword):
            showWifiPassword()
        case (.ErrorRange, .Searching):
            showSearching()
        case (.ErrorRange, .Provisioning):
            showProvisioning()
        case (.ProvisioningError(let error), .Start):
            showStartPage()
            
        case (_, .ProvisioningSuccess):
            showProvisioningSuccess()
            
        default:
            break
        }
    }
    
    private func load() {
        SAVReachability.sharedInstance().addReachabilityObserver(self)
        Savant.provisioner().addDelegate(self)
        Savant.discovery().addDiscoveryObserver(self)
        updateHosts()
        
        navController.delegate = self
		RootViewController.sav_addChildViewController(backgroundController)
        RootViewController.view.sav_addFlushConstraintsForView(backgroundController.view)
        showStartPage()
        RootViewController.sav_addChildViewController(navController)
    }
    
    private func unload() {
        SAVReachability.sharedInstance().removeReachabilityObserver(self)
        Savant.provisioner().removeDelegate(self)
        Savant.discovery().removeDiscoveryObserver(self)
        navController.sav_removeFromParentViewController()
    }
    
    private func showStartPage() {
        let viewController = StartPage(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }
    
    private func showExistingHostNotFound() {
        let tips = [NSLocalizedString("You may be on the wrong Wi-Fi Network. Make sure you are connected to your Home wi-fi network.", comment: ""),
                    NSLocalizedString("Contact your integrator for help", comment: "")]
        
        let viewController = ExistingHostNotFoundViewController(coordinator: coordinator, tips: tips)
        navController.pushViewController(viewController, animated: true)
    }
	
	private func showBadWifiPassword() {
		let viewController = BadWifiPasswordController(coordinator: coordinator)
		navController.pushViewController(viewController, animated: true)
        
        viewController.retryClosure = {
            if let host = self.currentHost {
                self.coordinator.transitionToState(.WifiPassword)
            } else {
                self.coordinator.transitionToState(.Searching)
            }
        }
	}
	
	private func showInternalError() {
		let viewController = InternalErrorController(coordinator: coordinator)
		navController.pushViewController(viewController, animated: true)
        
        viewController.retryClosure = {
            if let host = self.currentHost {
                self.coordinator.transitionToState(.Provisioning)
            } else {
                self.coordinator.transitionToState(.Searching)
            }
        }
	}
	
	private func showHostOutOfRange() {
		let viewController = HostOutOfRangeController(coordinator: coordinator)
		navController.pushViewController(viewController, animated: true)
        
        viewController.retryClosure = {
            if let host = self.currentHost {
                self.coordinator.transitionToState(.Provisioning)
            } else {
                self.coordinator.transitionToState(.Searching)
            }
        }
	}
    
    private func showPlugInHost() {
        if count(currentHosts) > 1 && coordinator.currentState != .HostsFound {
            coordinator.transitionToState(.HostsFound)
        } else if let host = currentHost {
            coordinator.transitionToState(.HostFound)
        } else {
            let viewController = PlugInYourHostViewController(coordinator: coordinator)
            navController.pushViewController(viewController, animated: true)
        }
    }
    
    private func showSearching() {
        if count(currentHosts) > 1 && coordinator.currentState != .HostsFound {
            coordinator.transitionToState(.HostsFound)
        } else if let host = self.currentHost {
            coordinator.transitionToState(.HostFound)
        } else {
            pulseViewController = PulsingViewController(coordinator: coordinator, state: .Searching)
            if let viewController = pulseViewController {
                viewController.setState(.Searching)
                navController.pushViewController(viewController, animated: true)
            }
            
            searchTimer = NSTimer.sav_scheduledBlockWithDelay(2.5, block: { [unowned self] () -> Void in
    
                if let ps: AnyObject = Savant.discovery().groupedSystems[SAVDiscoveryProvisionableSystemsKey] {
                        self.currentHosts = ps as! [ProvisionableDevice]
                }
                                
                if count(self.currentHosts) > 1 {
                    self.coordinator.transitionToState(.HostsFound)
                } else if let host = self.currentHost {
                    self.coordinator.transitionToState(.HostFound)
                } else {
                    self.coordinator.transitionToState(.HostNotFound)
                }
            })
        }
    }
    
    private func showHostFound() {
        let viewController = HostFoundViewController(coordinator: coordinator, uid: currentHost?.uid)
        navController.pushViewController(viewController, animated: true)
    }
    
    private func showHostsFound() {
        if hostsFoundModel == nil {
            hostsFoundModel = HostsFoundCollectionViewModel(hosts: currentHosts)
        }

        let viewController = HostsFoundCollectionViewController(coordinator: coordinator, model: hostsFoundModel!)
        navController.pushViewController(viewController, animated: true)
    }

    private func showHostFoundWifi(host: ProvisionableDevice) {
        currentHost = host
        let viewController = HostFoundWifiViewController(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }
    
    private func showWifiPassword() {
        let viewController = WifiPasswordViewController(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }

    private func showNoWifiPassword() {
        let viewController = NoWifiPasswordViewController(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }
    
    private func showHostNotFound() {
        let tips = [NSLocalizedString("Make sure your host is plugged in and powered on. A yellow LED light will flash to indicate its readiness", comment: ""),
            NSLocalizedString("Stand within 30 feet of your host to ensure the signal is strong enough to be detected by your mobile device.", comment: ""),
            NSLocalizedString("Make sure your phone is within 30 feet of your host.", comment: "")]
        
        let viewController = HostNotFoundViewController(coordinator: coordinator, tips: tips)
        navController.pushViewController(viewController, animated: true)    }

    private func showSwitchWifi() {
        let viewController = OpenSettingsViewController(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }
    
    private func showProvisioning() {
        pulseViewController = PulsingViewController(coordinator: coordinator, state: .Connecting)
        
        if let viewController = pulseViewController {
            navController.pushViewController(viewController, animated: true)
        }
        
// Need to serialize
//        NSUserDefaults.standardUserDefaults().setObject(wifiCredentials, forKey: wifiCacheKey())
        
        Savant.provisioner().provisionDevice(currentHost, withWifiCredentials: wifiCredentials)
    }
    
    private func wifiCacheKey() -> String {
//        return "onboarding-\(Savant.control().currentSystem?.homeID)-wifi"
        return "this-storage-method-needs-improvement"
    }
    
    private func showProvisioningSuccess() {
        if let viewController = pulseViewController {
            viewController.setState(.Success)
        }
        
        dispatch_after(2, dispatch_get_main_queue()) { () -> Void in
            RootCoordinator.transitionToState(.DeviceOnboarding)
        }
    }

    private func showProvisioningError(error: Int) {
        //Provisioning Result: {Not Available, Success, Invalid Configuration, Network Out Of Range, Invalid Key, Other Error}
        switch error {
        case 3:
            println("Contact JRL: recieved unexpected configuration error")
            self.coordinator.transitionToState(.ErrorInternal)
        case 4:
            self.coordinator.transitionToState(.ErrorRange)
        case 5:
            self.coordinator.transitionToState(.ErrorBadPassword)
        default:
            self.coordinator.transitionToState(.ErrorInternal)
        }
    }
    
    private func showBTLEWifi() {
        searchTimer.invalidate()
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            self.coordinator.transitionToState(.PlugInHost)
        #else
            if !SAVReachability.sharedInstance().bluetoothEnabled || !SAVReachability.sharedInstance().wifiEnabled {
                let viewController = WirelessRadioStatusViewController(coordinator: coordinator)
                navController.pushViewController(viewController, animated: true)
            } else {
                self.coordinator.transitionToState(.PlugInHost)
            }
        #endif
    }
    
    func currentSSIDDidChange(ssid: String!) {
        wifiCredentials.SSID = ssid
        wifiCredentials.authType = WifiAuthType.Any()
    }

    func wifiStatusDidChange(enabled: Bool) {
        radioStatusDidChange(enabled, bluetooth: SAVReachability.sharedInstance().bluetoothEnabled)
    }
    
    func bluetoothStatusDidChange(enabled: Bool) {
        if !enabled {
            currentHosts = [ProvisionableDevice]()
        }
        
        radioStatusDidChange(SAVReachability.sharedInstance().wifiEnabled, bluetooth: enabled)
    }
    
    func radioStatusDidChange(wifi: Bool, bluetooth: Bool) {
        if wifi && bluetooth {
            if self.coordinator.currentState == .EnableBTLEWifi {// && self.coordinator.previousState == .Start  {
                self.coordinator.transitionToState(.Searching)
//            } else if let state = self.coordinator.previousState where self.coordinator.currentState == .EnableBTLEWifi {
//                self.coordinator.transitionToState(state)
            }
        } else {
            if shouldShowRadioStatus(self.coordinator.currentState) {
                self.coordinator.transitionToState(.EnableBTLEWifi)
            }
        }
    }
    
    func shouldShowRadioStatus(state: HostOnboardingState) -> Bool {
        if contains([.PlugInHost, .Searching, .HostNotFound, .HostsFound, .HostFound, .HostFoundWifi(nil), .WifiPassword, .NoWifiPassword, .SwitchWifi], state) {
            return true
        } else {
            return false
        }
    }
    
    func updateHosts() {
        if let hosts = Savant.discovery().groupedSystems[SAVDiscoveryProvisionableSystemsKey] as? [ProvisionableDevice] {
            updateHosts(hosts)
        }
    }
    
    func updateHosts(hosts: [ProvisionableDevice]) {
        var provisionableHosts = [ProvisionableDevice]()
        for host in hosts {
            if host.savantDeviceType == .Host {
                provisionableHosts.append(host)
            }
        }
        
        currentHosts = provisionableHosts
        
        if count(currentHosts) == 1 {
            currentHost = currentHosts[0]
        }
    }
    
//    func hostTransitionState() -> HostOnboardingState {
//        if count(self.currentHosts) > 1 {
//            return .HostsFound
//        } else if let host = self.currentHost {
//            return .HostFound
//        } else {
//            return .HostNotFound
//        }
//    }
}

extension HostOnboardingCoordinatorManager: DiscoveryDelegate {
    func discoveryDidUpdateSystemList(discovery: SAVDiscovery!) {
        if !contains([.Provisioning, .HostFoundWifi(nil), .WifiPassword, .NoWifiPassword], coordinator.currentState) {
            if let devices = discovery.groupedSystems[SAVDiscoveryProvisionableSystemsKey] as? [ProvisionableDevice] {
                updateHosts(devices)
                
                // Navigate to hosts found if we are on Host Found and find more hosts
                if count(currentHosts) > 1 && coordinator.currentState == .HostFound {
                    coordinator.transitionToState(.HostsFound)
                }

                // Update data source for hosts found model if we're on that page
                if coordinator.currentState == .HostsFound {
                    hostsFoundModel?.setupDataSource(currentHosts)
                }
            }
        } else {
            if let devices = discovery.groupedSystems[SAVDiscoveryProvisionableSystemsKey] as? [ProvisionableDevice] {
                
                if let host = currentHost where count(devices) > 0 {
                    var hostLost = true
                    for h in devices {
                        if h.uid == host.uid {
                            hostLost = false
                            break
                        }
                    }
                    
                    if (hostLost || count (currentHosts) == 0) && coordinator.currentState != .Provisioning {
                        println("Host(s) lost")
                        coordinator.transitionToState(.Searching)
                    }
                }
            }
        }
    }
    
    func discovery(discovery: SAVDiscovery!, didFindSystem system: SAVSystem!) {
        if system.hostID == currentHost?.uid {
            Savant.cloud().onboardSystem(system, completionHandler: { (success, error) in
                if success {
                    self.coordinator.transitionToState(.ProvisioningSuccess)
                } else {
                    //BS error code so we can just show 'internal error'
                    self.coordinator.transitionToState(.ProvisioningError(6))
                }
            })
        }
    }
}

extension HostOnboardingCoordinatorManager: SAVProvisionerDelegate {
    func didProvisionProvisionableDevice(device: Provisioner.ProvisionableDevice!, success: Bool, error: NSError!) {
        if success {
            println("Host Provisioned - Searching on WiFi (\(wifiCredentials.SSID))")
//            coordinator.transitionToState(.ProvisioningSuccess)
        } else {
            coordinator.transitionToState(.ProvisioningError(error.code))
        }
    }
}

extension HostOnboardingCoordinatorManager: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let animator = ZoomOutAnimator(toAlpha: 0.0)

        if toVC as? StartPage != nil {
            animator.presenting = true
        } else {
            animator.presenting = false
        }
        
        return animator
    }
}
