//
//  DeviceOnboardingCoordinator.swift
//  Savant
//
//  Created by Julian Locke on 5/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import CoreBluetooth

func NewDeviceOnboardingCoordinator() -> CoordinatorReference<DeviceOnboardingState> {
    return Coordinator(coordinatorManager: DeviceOnboardingCoordinatorManager())
}

enum DeviceOnboardingState: Equatable {
    case Unloaded
    case ConnectDevices
    case Searching
    case DevicesFound
    case RoomPicker(device:ConfigurableProvisionableDevice?)
    case Provisioning(devicesToProvision:[ConfigurableProvisionableDevice])
    case NameHome
    case EnableBTLEWifi
	case DevicesAdded(numberOfDevices:Int)
	
    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .ConnectDevices:
                return "ConnectDevices"
            case .Searching:
                return "Searching"
            case .DevicesFound:
                return "DevicesFound"
            case .RoomPicker(let device):
                return "RoomPicker"
            case Provisioning(let devicesToProvision):
                return "Provisioning"
            case .NameHome:
                return "NameHome"
            case .EnableBTLEWifi:
                return "EnableBTLEWifi"
			case .DevicesAdded(let numberOfDevices):
				return "DevicesAdded"

            default:
                return "Implement"
            }
        }
    }
}

func ==(lhs: DeviceOnboardingState, rhs: DeviceOnboardingState) -> Bool {
    return lhs.description == rhs.description
}

class DeviceOnboardingCoordinatorManager: NSObject, CoordinatorManager, UINavigationControllerDelegate, SAVProvisionerDelegate, DiscoveryDelegate, SAVReachabilityDelegate {
    
    private override init() {}
    
    typealias StateType = DeviceOnboardingState
    var currentDevice:ConfigurableProvisionableDevice?
    var currentDevices = [ConfigurableProvisionableDevice]()
    
    var toProvision = Set<ConfigurableProvisionableDevice>()
    var provisioned = Set<ConfigurableProvisionableDevice>()

    var toOnboard = Set<ConfigurableProvisionableDevice>()
    var onboarded = Set<ConfigurableProvisionableDevice>()
    
    weak var provisioningTimer:NSTimer?
    weak var onboardingTimer:NSTimer?

    var devicesFoundModel: DevicesFoundCollectionViewModel?
    var searchTimer:NSTimer?

    var wifiCredentials = WifiCredentials()
    let navController = UINavigationController()
    let backgroundController = ImageViewController(image: UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("LandingPage", ofType: "jpg")!)!)

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
        case (.Unloaded, .ConnectDevices):
            load()
            
        case (.ConnectDevices, .Searching):
            showSearching()
        case (.Searching, .ConnectDevices):
            showConnectDevicesHelp()
        case (.Searching, .DevicesFound):
            showDevicesFound()
        case (.Searching, .ConnectDevices):
            showConnectDevicesHelp()
        case (_, .EnableBTLEWifi):
            showBTLEWifi()
        case (.EnableBTLEWifi, .Searching):
            showSearching()
        case (.EnableBTLEWifi, .ConnectDevices):
            showConnectDevicesHelp()
        case (.EnableBTLEWifi, .DevicesFound):
            showDevicesFound()
        case (.DevicesFound, .ConnectDevices):
            showConnectDevicesHelp()
		case (.DevicesFound, .RoomPicker(let device)):
			showRoomPicker(device)
		case (.RoomPicker, .DevicesFound):
			showDevicesFound()
        case (.DevicesFound, .Provisioning(let devicesToProvision)):
            showProvisioning(devicesToProvision)
		case (.RoomPicker, .DevicesAdded(let numberOfDevices)): // Remove later?
			showDevicesAdded(numberOfDevices)
		case (.Searching, .DevicesAdded(let numberOfDevices)): // Remove later?
			showDevicesAdded(numberOfDevices)
        default:
            println("Implement case")
            break
        }
    }

    private func load() {
        SAVReachability.sharedInstance().addReachabilityObserver(self)
        Savant.provisioner().addDelegate(self)
        Savant.discovery().addDiscoveryObserver(self)
        
        if let devices = Savant.discovery().combinedPeripherals as? [ConfigurableProvisionableDevice] {
            var ConfigurableProvisionableDevices = devices as [ConfigurableProvisionableDevice]
        }
		
        navController.delegate = self
		navController.navigationBarHidden = true
        RootViewController.sav_addChildViewController(backgroundController)
        RootViewController.view.sav_addFlushConstraintsForView(backgroundController.view)
        RootViewController.sav_addChildViewController(navController)
    }
    
    private func unload() {
        SAVReachability.sharedInstance().removeReachabilityObserver(self)
        Savant.provisioner().removeDelegate(self)
        Savant.discovery().removeDiscoveryObserver(self)
        navController.sav_removeFromParentViewController()
    }
    
    private func showConnectDevicesHelp() {
        let viewController = ConnectDevicesHelpViewController(coordinator: coordinator)
        navController.pushViewController(viewController, animated: true)
    }
	
    private func showRoomPicker(device: ConfigurableProvisionableDevice?) {
		let viewController = RoomPickerViewController(delegate: self, selectedRoom:device?.room, background: .Default)
        currentDevice = device
		navController.pushViewController(viewController, animated: true)
	}
	
    private func dismissRoomPicker() {
        navController.popViewControllerAnimated(true)
    }
    
    private func showProvisioning(devicesToProvision: [ConfigurableProvisionableDevice]) {
        println("show provision called \(devicesToProvision)")

        let viewController = PulsingViewController(coordinator: coordinator, state: .Connecting)
        navController.pushViewController(viewController, animated: true)
        
        provision(devicesToProvision)
    }
    
    private func provision(devicesToProvision: [ConfigurableProvisionableDevice]) {
        searchTimer = NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: Selector("provisioningTimedOut"), userInfo: nil, repeats: false)
        
        toProvision = Set<ConfigurableProvisionableDevice>()
        provisioned = Set<ConfigurableProvisionableDevice>()
        
        println("provision called \(devicesToProvision)")
        
        for device in devicesToProvision {
//            let wifiCredentials:WifiCredentials? = NSUserDefaults.standardUserDefaults().objectForKey(wifiCacheKey()) as! WifiCredentials?
            
            println(device.provisionableDevice)

            toProvision.insert(device)
            
            var wifiCredentials:WifiCredentials = WifiCredentials()
            wifiCredentials.presharedKey = "Racepoint"
            wifiCredentials.SSID = "SavantAliciaT"
            wifiCredentials.authType = WifiAuthType.Any()

            Savant.provisioner().provisionDevice(device.provisionableDevice, withWifiCredentials: wifiCredentials)
        }
    }
    
    private func provisioningTimedOut() {
        var successess = 0
        var failures = 0
        
        for dev in toProvision {
            if (provisioned.contains(dev)) {
                successess++
            } else {
                failures++
            }
        }
        
        if successess == toProvision.count {
            //show success
        } else if failures == toProvision.count {
            //show all failed
        } else {
            //show #success then #failues
        }
    }
    
    private func onboard(devicesToOnboard: [ConfigurableProvisionableDevice?]) {
        //
    }
    
    private func wifiCacheKey() -> String {
//        return "onboarding-\(Savant.control().currentSystem?.homeID)-wifi"
        return "this-storage-method-needs-improvement"
    }

    private func showSearching() {
        let viewController = PulsingViewController(coordinator: coordinator, state: .SearchingSavantDevices)
        navController.pushViewController(viewController, animated: true)
        
        searchTimer = NSTimer.sav_scheduledBlockWithDelay(2.5, block: { [unowned self] () -> Void in
            
            var configurableDevices = [ConfigurableProvisionableDevice]()
            
            if let devices = Savant.discovery().combinedPeripherals as? [ProvisionableDevice] {
                for device in devices {
                    configurableDevices.append(ConfigurableProvisionableDevice(aProvisionableDevice: device))
                }
            }
            
            self.currentDevices = configurableDevices
            
            if count(self.currentDevices) > 0 {
                self.coordinator.transitionToState(.DevicesFound)
            } else if let device = self.currentDevice {
                self.coordinator.transitionToState(.DevicesFound)
            } else {
                self.coordinator.transitionToState(.ConnectDevices)
            }
        })
    }

    private func showDevicesFound() {
		var configurableDevices = [ConfigurableProvisionableDevice]()
		
		if let devices = Savant.discovery().combinedPeripherals as? [ProvisionableDevice] {
			for device in devices {                
                let cpd = (ConfigurableProvisionableDevice(aProvisionableDevice: device))
				configurableDevices.append(cpd)
			}
			currentDevices = configurableDevices
		}
		
		if devicesFoundModel == nil {
			devicesFoundModel = DevicesFoundCollectionViewModel(devices: currentDevices)
		}
		
		let viewController = DevicesFoundCollectionViewController(coordinator: coordinator, model: devicesFoundModel!)
		navController.pushViewController(viewController, animated: true)
    }
	
	private func showDevicesAdded(numberOfDevices:Int) {
		let viewController = PulsingViewController(coordinator: coordinator, state: PulseState.DevicesAdded, numberOfDevices: numberOfDevices)
		self.navController.pushViewController(viewController, animated: true)
	}
	
    private func showBTLEWifi() {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            self.coordinator.transitionToState(.ConnectDevices)
        #else
            if !SAVReachability.sharedInstance().bluetoothEnabled || !SAVReachability.sharedInstance().wifiEnabled {
                let viewController = WirelessRadioStatusViewController(coordinator: coordinator)
                navController.pushViewController(viewController, animated: true)
            } else {
                self.coordinator.transitionToState(.ConnectDevices)
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
            currentDevices = [ConfigurableProvisionableDevice]()
        }
        
        radioStatusDidChange(SAVReachability.sharedInstance().wifiEnabled, bluetooth: enabled)
    }
    
    func radioStatusDidChange(wifi: Bool, bluetooth: Bool) {
        if wifi && bluetooth {
            if self.coordinator.currentState == .EnableBTLEWifi && self.coordinator.previousState == .Searching  {
                self.coordinator.transitionToState(.Searching)
            }
            else if let state = self.coordinator.previousState where self.coordinator.currentState == .EnableBTLEWifi {
                self.coordinator.transitionToState(state)
            }
        } else {
            if shouldShowRadioStatus(self.coordinator.currentState) {
                self.coordinator.transitionToState(.EnableBTLEWifi)
            }
        }
    }
    
    func shouldShowRadioStatus(state: DeviceOnboardingState) -> Bool {
        if contains([.ConnectDevices, .Searching, .DevicesFound], state) {
            return true
        } else {
            return false
        }
    }
    
    func updateDevices(devices: [ConfigurableProvisionableDevice]) {
        var ConfigurableProvisionableDevices = [ConfigurableProvisionableDevice]()
        
        for device in devices {
            ConfigurableProvisionableDevices.append(device)
        }
        
        currentDevices = ConfigurableProvisionableDevices
    }
}

extension DeviceOnboardingCoordinatorManager: DiscoveryDelegate {
    
    func discoveryDidUpdateProvisionablePeripheralList(discovery: SAVDiscovery!) {
//
    }
}

extension DeviceOnboardingCoordinatorManager: SAVProvisionerDelegate {
    func didProvisionProvisionableDevice(device: Provisioner.ProvisionableDevice!, success: Bool, error: NSError!) {
        if (coordinator.currentState == .Provisioning(devicesToProvision:[])) {
            
            provisioned.insert(ConfigurableProvisionableDevice(aProvisionableDevice: device))
            
            var allProvisioned = true
            
            for dev in toProvision {
                if (!provisioned.contains(dev)) {
                    allProvisioned = false
                }
            }
            
            if allProvisioned {
                //show success
            }
        }
    }
}

extension DeviceOnboardingCoordinatorManager: UINavigationControllerDelegate {
    
    func navigationController(navig ationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let animator = ZoomOutAnimator(toAlpha: 0.0)
        
        if toVC as? StartPage != nil {
            animator.presenting = true
        } else {
            animator.presenting = false
        }
        
        return animator
    }
}

extension DeviceOnboardingCoordinatorManager: RoomPickerDelegate {
    func roomPicker(roomPicker:RoomPickerViewController, selectedRoom room: SAVRoom?) {
		currentDevice?.room = room
        coordinator.transitionBack()
    }
	func roomPickerCanceledSelection(roomPicker: RoomPickerViewController) {
		coordinator.transitionBack()
	}
}




