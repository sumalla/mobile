//
//  InterfaceCoordinator.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import Futures

func NewInterfaceCoordinator() -> CoordinatorReference<InterfaceState> {
    return Coordinator(coordinatorManager: InterfaceCoordinatorManager())
}

func ==(lhs: InterfaceState, rhs: InterfaceState) -> Bool {
    return lhs.description == rhs.description
}

enum InterfaceState: Equatable, Printable {
    case Unloaded
    case House
    case Rooms
    case Room(SAVRoom)
    case Scenes(SAVRoom?)
    case Devices(SAVRoom?)
    case Service(SAVService)
    case UserProfile
    case Settings
    case NotificationSettings

    var isDrawer: Bool {
        get {
            switch self {
            case .Scenes(let room):
                return true
            case .Devices(let room):
                return true
            default:
                return false
            }
        }
    }

    var isService: Bool {
        get {
            switch self {
            case .Service(let service):
                return true
            default:
                return false
            }
        }
    }

    var room: SAVRoom? {
        get {
            switch self {
            case .Scenes(let room):
                return room
            case .Devices(let room):
                return room
            case .Room(let room):
                return room
            default:
                return nil
            }
        }
    }

    var description: String {
        get {
            switch self {
            case .Unloaded:
                return "Unloaded"
            case .House:
                return "House"
            case .Room(let room):
                return "Room: \(room.roomId)"
            case .Rooms:
                return "Rooms"
            case .Scenes(let room):
                if let r = room {
                    return "Scenes: \(r.roomId)"
                } else {
                    return "Scenes"
                }
            case .Devices(let room):
                if let r = room {
                    return "Devices: \(r.roomId)"
                } else {
                    return "Devices"
                }
            case .Service(let service):
                return "Service: \(service.serviceString)"
            case .UserProfile:
                return "UserProfile"
            case .Settings:
                return "Settings"
            case .NotificationSettings:
                return "NotificationSettings"
            }
        }
    }
}

var drawerController: SCUDrawerViewController!
let serviceCache = FutureCache<[SAVService]>()

class InterfaceCoordinatorManager: NSObject, CoordinatorManager {

    private override init() {}

    typealias StateType = InterfaceState

    let roomsController = RoomsCollectionController(collectionViewLayout: VerticalFlowLayout())
    let scenesController = ScenesCollectionController(collectionViewLayout: VerticalFlowLayout())
    let devicesController = DevicesCollectionController(collectionViewLayout: VerticalFlowLayout())

    var navigationController: UINavigationController!

    let pullDownAnimator = PullDownAnimator()
    let roomAnimator = RoomImageAnimator()
    let zoomOutAnimator = ZoomOutAnimator()
    var hasLoaded = false
    
    weak var coordinator: CoordinatorReference<StateType>!

    var reconnectingView: SCULoadingView?
    
    let volumeListener = SCUVolumeListener()
    var volumeNotification: SCUHardButtonVolumeNotification?
    var volumeModel: SCUVolumeModel?
        
    var currentActiveServiceList: [SAVService]!
    var currentActiveService: SAVService?

    private var transitionState: StateType?

    var initialState: StateType {
        get {
            return .Unloaded
        }
    }

    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (.Rooms, .Room):
            fallthrough
        case (.Room, .Rooms):
            fallthrough
        case (.Rooms, .House):
            fallthrough
        case (.House, .Rooms):
            fallthrough
        case (.Rooms, .Service):
            fallthrough
        case (.Service, .Rooms):
            fallthrough
        case (.Unloaded, .House):
            fallthrough
        case (.House, .Devices):
            fallthrough
        case (.Room, .Devices):
            fallthrough
        case (.House, .Scenes):
            fallthrough
        case (.Room, .Scenes):
            fallthrough
        case (.House, .Service):
            fallthrough
        case (.Service, .House):
            fallthrough
        case (.Room, .Service):
            fallthrough
        case (.Service, .Room):
            fallthrough
        case (.Scenes, .Room):
            fallthrough
        case (.Scenes, .House):
            fallthrough
        case (.Devices, .Room):
            fallthrough
        case (.Devices, .House):
            fallthrough
        case (.Rooms, .UserProfile):
            fallthrough
        case (.UserProfile, .Rooms):
            fallthrough
        case (.Rooms, .Settings):
            fallthrough
        case (.Settings, .Rooms):
            fallthrough
        case (.Settings, .NotificationSettings):
            fallthrough
        case (.NotificationSettings, .Settings):
            fallthrough
        case (_, .Unloaded):
            return true
        default:
            return false
        }
    }

    func transition(#fromState: StateType, toState: StateType) {
        var transitioned = false

        // Just update state when closing drawer
        if fromState.isDrawer {
            drawerController.closeDrawerAnimated(true, completion: nil)
            transitioned = true
        }
        
        // Just update state when cancelling interactive transition
        if zoomOutAnimator.interactive && zoomOutAnimator.animating ||
            roomAnimator.interactive && roomAnimator.animating ||
            pullDownAnimator.interactive && pullDownAnimator.animating {
                transitioned = true
        }
        
        if !transitioned {
            if fromState.isService {
                // Dismiss any modal views when leaving service view
                RootViewController.dismissViewControllerAnimated(true, completion: nil)
            }

            switch toState {
            case .Unloaded:
                unload()
            case .Rooms:
                goToRoot()
            case .House:
                if fromState == .Unloaded {
                    Savant.control().addSystemStatusObserver(self)
                    SCUBackgroundHandler.sharedInstance().addDelegate(self)

                    if Savant.control().connectionState != .NotConnected {
                        load()
                    }
                } else {
                    showRoom(nil, animated: true)
                }

                if !Savant.control().connectedToSystem {
                    showReconnectingView(animated: false)
                }

            case .Room(let room):
                showRoom(room, animated: true)
            case .Scenes(let room):
                showScenes(room)
            case .Devices(let room):
                showDevices(room)
            case .Service(let service):
                showService(service)
            case .UserProfile:
                showUserProfile()
            case .Settings:
                showSettings()
            case .NotificationSettings:
                showNotificationSettings()
            default:
                break
            }
        }

        dispatch_async_main {
            self.stealVolumeIfAppropriate(fromState: fromState, toState: toState)
        }
    }

    private func load() {
        if !hasLoaded {
            hasLoaded = true
            navigationController = UINavigationController(navigationBarClass: TallNavBar.self, toolbarClass: nil)
            navigationController.pushViewController(roomsController, animated: false)
            drawerController = SCUDrawerViewController(rootViewController: navigationController)

            navigationController.delegate = self as UINavigationControllerDelegate

            zoomOutAnimator.delegate = self as PullDownAnimatorDelegate
            pullDownAnimator.delegate = self as PullDownAnimatorDelegate
            roomAnimator.delegate = self as PullDownAnimatorDelegate

            drawerController.maximumAnimationDuration = 0.2
            drawerController.delegate = self
            drawerController.edgeDraggingThreshold = 1
            drawerController.openWidthPercentage = 1
            drawerController.showShadow = true

            devicesController.devicesModel = DevicesDataModel(coordinator: coordinator)
            let devicesNav = UINavigationController(navigationBarClass: ExtraTallNavBar.self, toolbarClass: nil)
            devicesNav.pushViewController(devicesController, animated: false)
            drawerController.setViewController(devicesNav, forSide: .Left, level: .Below)

            scenesController.scenesModel = ScenesDataModel(coordinator: coordinator)
            let scenesNav = UINavigationController(navigationBarClass: ExtraTallNavBar.self, toolbarClass: nil)
            scenesNav.pushViewController(scenesController, animated: false)
            drawerController.setViewController(scenesNav, forSide: .Right, level: .Below)
            
            Savant.control().addSystemStatusObserver(self)
            SCUBackgroundHandler.sharedInstance().addDelegate(self)
            Savant.states().addActiveServiceObserver(self)

            // Load up the serviceCache
            if let rooms = Savant.data().allRoomIds() as? [String] {

                serviceCache.add("home", future: future({
                    if let services = Savant.data().servicesFilteredByService(SAVService()) as? [SAVService] {
                        return services
                    } else {
                        return [SAVService]()
                    }
                }))

                for room in rooms {
                    let service = SAVService(zone: room, component: nil, logicalComponent: nil, variantId: nil, serviceId: nil)
                    serviceCache.add(room, future: future({
                        if let services = Savant.data().servicesFilteredByService(service) as? [SAVService] {
                            return services
                        } else {
                            return [SAVService]()
                        }
                    }))
                }
            }
        }
        
        roomsController.roomsModel = RoomsDataModel(coordinator: coordinator)

        RootViewController.sav_addChildViewController(drawerController)
        RootViewController.view.sav_addFlushConstraintsForView(drawerController?.view)

        showRoom(nil, animated: false)
    }

    private func unload() {
        reconnectingView?.removeFromSuperview()
        reconnectingView = nil
        Savant.control().removeSystemStatusObserver(self)
        Savant.control().disconnect()
        Savant.states().removeActiveServiceObserver(self)
        SCUBackgroundHandler.sharedInstance().removeDelegate(self)

        if hasLoaded {
            drawerController.closeDrawerAnimated(true, completion: nil)
            drawerController.delegate = nil
            drawerController.sav_removeFromParentViewController()
            drawerController = nil
            serviceCache.cancelAndRemoveAll()
        }
    }

    private func goToRoot() {
        drawerController.closeDrawerAnimated(true, completion: nil)
        navigationController.popToRootViewControllerAnimated(true)
    }

    private func showRoom(room: SAVRoom?, animated: Bool) {
        for vc in navigationController.viewControllers {
            if let tc = vc as? RoomController {
                var found = false
                if let r1 = tc.room?.roomId, r2 = room?.roomId where r1 == r2 {
                    found = true
                } else if tc.room == nil && room == nil {
                    found = true
                }

                if found {
                    navigationController.popToViewController(tc, animated: animated)
                    let panGesture = (room != nil) ? roomAnimator.panGesture : zoomOutAnimator.panGesture

                    tc.view.addGestureRecognizer(panGesture)

                    return
                }
            }
        }
        
        let panGesture = (room != nil) ? roomAnimator.panGesture : zoomOutAnimator.panGesture

        let vc = RoomController(room: room, coordinator: coordinator, panGesture: panGesture)
        navigationController.pushViewController(vc, animated: animated)
    }

    private func showScenes(room: SAVRoom?) {
        scenesController.scenesModel.filterScenes(coordinator.previousState?.room)
        drawerController.openDrawerFromSide(.Right, animated: true, completion: nil)
    }

    private func showDevices(room: SAVRoom?) {
        devicesController.devicesModel.filterDevices(coordinator.previousState?.room)
        drawerController.openDrawerFromSide(.Left, animated: true, completion: nil)
    }

    private func showService(service: SAVService) {
        let global = coordinator.previousState == .House
        
        var vc: ServiceViewController?
        
        if let serviceId = service.serviceId {
            switch serviceId {
            case "SVC_AV_APPLEREMOTEMEDIASERVER":
                fallthrough
            case "SVC_AV_APPLEREMOTEMEDIASERVERAUDIO":
                vc = AppleTVServiceViewController(service: service, global: global)
            default:
                break
            }
        }
        
        if let vc = vc {
            vc.dismissalHandler = { [unowned self] in
                self.coordinator.transitionBack()
            }
            
            if !pullDownAnimator.interactive {
                let navController = UINavigationController(navigationBarClass: TallNavBar.self, toolbarClass: nil)
                navController.pushViewController(vc, animated: false)
                navController.transitioningDelegate = self
                RootViewController.presentViewController(navController, animated: true, completion: nil)
            }
            
            vc.panGesture = pullDownAnimator.panGesture
        } else {
            let asvc = SCUServiceViewControllerManager.viewControllerForService(service)
            
            if let asvc = asvc {
                asvc.dismissalCompletionBlock = { [weak self] in
                    if let s = self {
                        s.coordinator.transitionBack()
                    }
                }
                
                let navController = UINavigationController(navigationBarClass: TallNavBar.self, toolbarClass: SCUNavBarToolbar.self)
                navController.pushViewController(asvc, animated: false)
                navController.transitioningDelegate = self
                
                asvc.panGesture = pullDownAnimator.panGesture
                
                if !pullDownAnimator.interactive {
                    RootViewController.presentViewController(navController, animated: true, completion: nil)
                }
            } else {
                var manualPowerOn = true
                if let services = Savant.states().activeServices() as? [SAVService] {
                    if contains(services, service) {
                        manualPowerOn = true
                    }
                }
                
                if manualPowerOn {
                    let request = SAVServiceRequest(service: service)
                    request.request = "PowerOn"
                    Savant.control().sendMessage(request)
                }
                
                dispatch_async_main {
                    self.coordinator.transitionBack()
                }
            }
        }
    }

    private func showUserProfile() {
        navigationController.pushViewController(UserProfileViewController(coordinator: coordinator), animated: true)
    }
    
    private func showSettings() {
        navigationController.pushViewController(SettingsViewController(coordinator: coordinator), animated: true)
    }
    
    private func showNotificationSettings() {
        //TODO: navigationController.pushViewController(NotificationSettingsViewController(coordinator: coordinator), animated: true)
    }
    
    private func startStealingVolume(service: SAVService, title: String) {
        if (volumeNotification == nil) {
            let window = UIApplication.sharedApplication().keyWindow
            volumeNotification = SCUHardButtonVolumeNotification(frame: CGRectZero)
            
            var newState: InterfaceState?
            
            volumeNotification!.setRoomName(title)
            window?.addSubview(volumeNotification!)
            window?.sav_addCenteredConstraintsForView(volumeNotification!)
        }
        
        volumeListener.listening = true
        volumeListener.delegate = self
        volumeModel = SCUVolumeModel(service: service)
        volumeModel?.delegate = self
    }
    
    private func stopStealingVolume() {
        volumeListener.listening = false
        volumeListener.delegate = nil
        volumeModel?.delegate = nil
        volumeModel = nil
        volumeNotification?.hide()
        volumeNotification = nil
    }
    
    private func stealVolumeIfAppropriate(#fromState: StateType, toState: StateType) {
        if (fromState != toState) {
            stopStealingVolume()
        }
        
        var roomId: String?
        
        switch (fromState, toState) {
        case (_, .Service(let svc)):
            roomId = svc.zoneName
        case (_, .Room(let room)):
            roomId = room.roomId
        case (.Room (let room), .Scenes):
            roomId = room.roomId
        case (.Room (let room), .Devices):
             roomId = room.roomId
        default:
            break
        }
        
        if let roomId = roomId {
            let services = Savant.states().activeServiceListForRoom(roomId)
            
            if services.count == 1, let firstService = services.first as? SAVService {
                startStealingVolume(firstService, title: roomId)
            }
        }
    }
}

extension InterfaceCoordinatorManager: SCUDrawerViewControllerDelegate {

    func shouldDrawer(drawer: SCUDrawerViewController, beginDraggingFromSide drawerSide: SCUDrawerSide) -> Bool {
        if drawer.open {
            return true
        } else {
            var shouldOpen = false

            var newState: InterfaceState?

            if drawerSide == .Left {
                newState = .Devices(nil)
            } else if drawerSide == .Right {
                newState = .Scenes(nil)
            }

            if let newState = newState {
                if coordinator.canTransitionToState(newState) {
                    shouldOpen = true
                }
            }

            if shouldOpen {
                if drawerSide == .Right {
                    switch coordinator.currentState {
                    case .House:
                        scenesController.scenesModel.filterScenes(nil)
                    case .Room(let room):
                        scenesController.scenesModel.filterScenes(room)
                    default:
                        break
                    }
                } else if drawerSide == .Left {
                    switch coordinator.currentState {
                    case .House:
                        devicesController.devicesModel.filterDevices(nil)
                    case .Room(let room):
                        devicesController.devicesModel.filterDevices(room)
                    default:
                        break
                    }
                }
            }
            
            return shouldOpen
        }
    }

    func drawer(drawer: SCUDrawerViewController, didOpenFromSide drawerSide: SCUDrawerSide) {
        var newState: InterfaceState?

        if drawerSide == .Left {
            newState = .Devices(coordinator.previousState?.room)
        } else if drawerSide == .Right {
            newState = .Scenes(coordinator.previousState?.room)
        }

        if let newState = newState {
            coordinator.transitionToState(newState)
        }
    }

    func drawer(drawer: SCUDrawerViewController, didCloseFromSide drawerSide: SCUDrawerSide) {
        if coordinator.currentState.isDrawer {
            coordinator.transitionBack()
        }
    }

}

extension InterfaceCoordinatorManager: UINavigationControllerDelegate {

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if let roomsController = toVC as? RoomsCollectionController, roomController = fromVC as? RoomController {
            if let room = roomController.room {
                roomAnimator.presenting = false
                return roomAnimator
            } else {
                zoomOutAnimator.presenting = false
                return zoomOutAnimator
            }
        } else if let roomsController = fromVC as? RoomsCollectionController, roomController = toVC as? RoomController {
            if let room = roomController.room, indexPath = roomsController.roomsModel.indexOfRoom(room), cell = roomsController.collectionView?.cellForItemAtIndexPath(indexPath) as? RoomCell {
                roomAnimator.presenting = true

                roomAnimator.cellImage = cell.captureView.sav_rasterizedImage()
                roomAnimator.navBarImage = roomsController.navBar.sav_rasterizedImage()
                roomAnimator.modelItem = roomsController.roomsModel.itemForIndexPath(indexPath)
                roomAnimator.cellFrame = cell.contentView.convertRect(cell.contentView.bounds, toView: nil)

                return roomAnimator
            } else {
                zoomOutAnimator.presenting = true
                return zoomOutAnimator
            }
        }

        return nil
    }

    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if zoomOutAnimator.interactive {
            return zoomOutAnimator
        } else if roomAnimator.interactive {
            return roomAnimator
        }
        
        return nil
    }
}

extension InterfaceCoordinatorManager: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let transitionState = transitionState where transitionState.isService {
            pullDownAnimator.mode = .Below
            pullDownAnimator.presenting = false
            return pullDownAnimator
        }

        return nil
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if pullDownAnimator.interactive {
           return pullDownAnimator
        } else if roomAnimator.interactive {
            return roomAnimator
        }
        
        return nil
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        pullDownAnimator.presenting = true
        return pullDownAnimator
    }
}

extension InterfaceCoordinatorManager: PullDownAnimatorDelegate {

    func pullDownDidBegin(animator: PullDownAnimator) {
        transitionState = coordinator.currentState

        if coordinator.currentState.isService {
            coordinator.transitionBack()
        } else {
            coordinator.transitionToState(.Rooms)
        }
    }

    func pullDownDidCancel(animator: PullDownAnimator) {
        if let transitionState = transitionState {
            coordinator.transitionToState(transitionState)
        }

        transitionState = nil
    }

    func pullDownDidUpdate(animator: PullDownAnimator, percentComplete: CGFloat) {

    }

    func pullDownDidFinish(animator: PullDownAnimator) {
        transitionState = nil
    }
}

extension InterfaceCoordinatorManager: SystemStatusDelegate {

    func showReconnectingView(#animated: Bool) {
        if reconnectingView == nil {
            let loadingIndicator = SCULoadingView()
            let topView = UIView.sav_topView()
            topView.addSubview(loadingIndicator)
            topView.sav_addFlushConstraintsForView(loadingIndicator)
            reconnectingView = loadingIndicator

            if animated {
                loadingIndicator.alpha = 0

                UIView.animateWithDuration(0.35) {
                    loadingIndicator.alpha = 1
                }
            }
        }

        if let reconnectingView = reconnectingView {
            if let system = Savant.control().currentSystem {
                reconnectingView.title = String(format: NSLocalizedString("Searching for %@", comment: ""), system.name)
            } else {
                reconnectingView.title = NSLocalizedString("Searching", comment: "")
            }

            reconnectingView.progressViewLabel = ""
            reconnectingView.progressView.hidden = true
            reconnectingView.progressView.progress = 0
            reconnectingView.buttonTitles = [NSLocalizedString("Other Systems", comment: "").uppercaseString]
            reconnectingView.callback = { _ in
                RootCoordinator.transitionToState(.HomePicker)
            }
        }
    }

    func establishedConnectionDidFail() {
        showReconnectingView(animated: true)
    }

    func connectionIsReady() {
        if !hasLoaded {
            load()
        }

        if let rv = reconnectingView {
            UIView.animateWithDuration(0.35, animations: {
                rv.alpha = 0
            }, completion: { _ in
                rv.removeFromSuperview()
                self.reconnectingView = nil
            })
        }
    }

    func connectionDidReceiveConfigurationDownloadUpdate(progress: Float, isInstalling: Bool) {
        reconnectingView?.progressView.hidden = false

        let halfProgress = progress / 2

        if isInstalling {
            reconnectingView?.progressView.progress = halfProgress + 0.5
        } else {
            reconnectingView?.progressView.progress = halfProgress
        }

        if let system = Savant.control().currentSystem {
            reconnectingView?.title = String(format: NSLocalizedString("Connecting to %@", comment: ""), system.name)
        } else {
            reconnectingView?.title = NSLocalizedString("Searching", comment: "")
        }

        reconnectingView?.buttonTitles = [NSLocalizedString("Cancel", comment: "").uppercaseString]
    }

}

extension InterfaceCoordinatorManager: ActiveServiceObserver {
    
    func room(roomId: String, didUpdateActiveService service: SAVService?) {
        currentActiveService = service

        dispatch_async_main {
            self.stealVolumeIfAppropriate(fromState: self.coordinator.currentState, toState: self.coordinator.currentState)
        }
    }
    
    func room(roomId: String, didUpdateActiveServiceList services: [AnyObject]) {
        currentActiveServiceList = (services as? [SAVService])!
    }
}

extension InterfaceCoordinatorManager: SCUVolumeListenerDelegate {
    
    func volumeListenerDidIncrement(listener: SCUVolumeListener!) {
        volumeModel?.increaseVolume()
        updateVolumeNotification(volumeModel!.currentVolume + 1, oldVolume: volumeModel!.currentVolume)
    }
    
    func volumeListenerDidDecrement(listener: SCUVolumeListener!) {
        volumeModel?.decreaseVolume()
        updateVolumeNotification(volumeModel!.currentVolume - 1, oldVolume: volumeModel!.currentVolume)
    }
    
    private func updateVolumeNotification(var newVolume: Int, var oldVolume: Int) {
        if volumeModel!.discrete && (volumeModel!.serviceGroup.activeServices.count == 1) {
            
            let currentSerice: SAVService? = self.volumeModel?.serviceGroup.activeServices.first as? SAVService
            
            volumeNotification?.interact()
            volumeNotification?.setRoomName(currentSerice?.zoneName)
            
            return
        }
        
        if let count = volumeModel?.serviceGroup.activeServices.count where (count > 1) {
            volumeNotification?.setNumberOfRooms(count)
        }
        else if let count = volumeModel?.serviceGroup.activeServices.count where (count == 1) {
            let currentSerice: SAVService? = self.volumeModel?.serviceGroup.activeServices.first as? SAVService
            volumeNotification?.setRoomName(currentSerice?.zoneName)
        }
        
        if ((newVolume - oldVolume) > 0) {
            volumeNotification?.showVolumeUp()
        } else {
            volumeNotification?.showVolumeDown()
        }
    }
}

extension InterfaceCoordinatorManager: SCUVolumeModelDelegate {
    
    func didUpdateVolume(volume: Int) {
        volumeNotification?.updatePercentage(volume * 2)
    }
    
    func didUpdateMuteStatus(muted: Bool) {}
    
    func didUpdateDiscreteVolumeStatus(discreteVolumeAvailable: Bool) {}
    
    func isTracking() -> Bool {
        return false
    }
    
    func updateGlobalVolume() {}
    
    func showRoomVolume() -> Bool {
        return false
    }
    
    func showGlobalRoomVolume() {}
    
    func hideGlobalRoomVolume() {}
}

extension InterfaceCoordinatorManager: SCUBackgroundHandlerDelegate {

    func backgroundHandlerEnterBackground() {
        stopStealingVolume()
        showReconnectingView(animated: false)
        Savant.control().suspend()
    }

    func backgroundHandlerEnterForeground() {
        dispatch_async_main {
            self.stealVolumeIfAppropriate(fromState: self.coordinator.currentState, toState: self.coordinator.currentState)
        }

        Savant.control().resume()
    }
    
    func backgroundHandlerWillResignActive() {
        stopStealingVolume()
    }
}
