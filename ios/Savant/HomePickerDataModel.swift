//
//  HomePickerDataModel.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

protocol HomePickerConnectionDelegate : NSObjectProtocol {
    func showConnectButton(indexPath: NSIndexPath)
    func showProgressSpinner(show: Bool, indexPath: NSIndexPath)
    func updateProgressStatusBar(progress: CGFloat, indexPath: NSIndexPath)
}

class HomePickerModelItem: ModelItem {
    var remote = false
    var showInviteButton = false
    var plus = false
    var cardType: HomePickerCardType = .LocalMinus
    var animating = false
    var system: SAVSystem?
}

class HomePickerDataModel: DataSource {

    let coordinator: CoordinatorReference<HomePickerState>
    var hasLoaded = false
    weak var connectionDelegate: HomePickerConnectionDelegate?
    var currentHostId: String?
    var onboardingHomes = Set<String>()

    init(coordinator c: CoordinatorReference<HomePickerState>) {
        coordinator = c
        super.init()
    }
    
    override func didAppear() {
        super.didAppear()
        
        if onboardingHomes.count > 0 {
            onboardingHomes = Set<String>()
            updateSystems(Savant.discovery().groupedSystems)
        }
    }

    func updateSystems(systems: NSDictionary!) {
        let localSystems = systems[SAVDiscoveryLocalSystemsKey] as? [SAVSystem]
        let cloudSystems = systems[SAVDiscoveryCloudSystemsKey] as? [SAVSystem]

        var items = [HomePickerModelItem]()

        if let cloudSystems = cloudSystems {
            items += parse(systems: cloudSystems)
        }

        if let localSystems = localSystems {
            items += parse(systems: localSystems)
        }

        if items.count == 0 {
            let item = HomePickerModelItem()
            RootCoordinator.transitionToState(.HostOnboarding)
        }

        setItems(items)
        
        if hasLoaded {
            reloader?.reloadData()
        } else {
            reloader?.insertSections(NSIndexSet(index: 0), animation: .None)
            hasLoaded = true
        }
    }

    func parse(#systems: [SAVSystem]) -> [HomePickerModelItem] {
        return map(systems) { (system) -> HomePickerModelItem in
            let modelItem = HomePickerModelItem()

            if system.cloudSystem && system.localURL == nil {
                modelItem.remote = true
            }

            if system.onboardKey != nil && Savant.cloud().hasCloudCredentials() {
                if self.onboardingHomes.contains(system.hostID) {
                    modelItem.cardType = .Onboarding
                } else {
                    modelItem.cardType = .Onboardable
                }
            } else if modelItem.remote && !system.cloudOnline {
                modelItem.cardType = .HostNotFound
            } else if modelItem.remote && system.cloudSystem {
                modelItem.cardType = .RemotePlus
            } else if !modelItem.remote && system.cloudSystem {
                modelItem.cardType = .LocalPlus
            } else if modelItem.remote {
                modelItem.cardType = .RemoteMinus
            } else if modelItem.showInviteButton {
                modelItem.cardType = .RequestAccess
            }

            modelItem.system = system
            modelItem.title = system.name
            return modelItem
        }
    }
    
    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        var item = super.itemForIndexPath(indexPath) as! HomePickerModelItem
        
        if let system = item.system where system.onboardKey != nil && Savant.cloud().hasCloudCredentials() {
            if self.onboardingHomes.contains(system.hostID) {
                item.cardType = .Onboarding
            } else {
                item.cardType = .Onboardable
            }
        }
        
        return item
    }
    
    func currentIndexPath() -> NSIndexPath? {
        let section = sectionForSection(0)
        if let section = section {
            if let items = section.items as? [HomePickerModelItem] {
                for (row, item) in enumerate(items) {
                    if let system = item.system where system.hostID == currentHostId {
                        return NSIndexPath(forItem: row, inSection: 0)
                    }
                }
            }
        }
        
        return nil
    }
    
    func removeItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        self.sections.removeAll(keepCapacity: false)
    }
    
    func numberOfSystems() -> Int {
        let section = sectionForSection(0)
        if let section = section {
            return section.count
        }
        return 0
    }

    func listenToButtonAtIndexPath(button: ProgressButtonView, indexPath: NSIndexPath) {
        button.mainButton.releaseCallback = { [weak self] in
            self?.handleButtonAtIndexPath(indexPath)
        }
    }
    
    func listenToSkipOnboardingButtonAtIndexPath(button: SCUButton, indexPath: NSIndexPath) {
        button.releaseCallback = { [weak self] in
            if let wSelf = self {
                var modelItem = wSelf.itemForIndexPath(indexPath) as! HomePickerModelItem
                
                if let system = modelItem.system {
                    wSelf.currentHostId = system.hostID
                    
                    if let indexPath = wSelf.currentIndexPath() {
                        wSelf.connectionDelegate?.showProgressSpinner(true, indexPath: indexPath)
                    }
                    
                    Savant.control().connectToSystem(system)
                }
            }
        }
    }
    
    func listenToRetryButtonAtIndexPath(button: ProgressButtonView, indexPath: NSIndexPath) {
        let modelItem = itemForIndexPath(indexPath) as! HomePickerModelItem
        
        button.mainButton.releaseCallback = { [weak self] in
            self?.connectionDelegate?.showProgressSpinner(true, indexPath: indexPath)

            let _ = Savant.discovery().cloudHomesWithCompletionHandler() { (success, systems, error) in

                if let systems = systems as? [SAVSystem] {
                    for system in systems {
                        if system.hostID == modelItem.system?.hostID && system.cloudOnline {
                            self?.handleButtonAtIndexPath(indexPath)
                            return
                        }
                    }
                }

                NSTimer.sav_scheduledBlockWithDelay(1) {
                    self?.connectionDelegate?.showConnectButton(indexPath)
                }
            }
        }
    }
    
    func listenToCancelButtonAtIndexPath(button: ProgressButtonView, indexPath: NSIndexPath) {
        button.cancelButton.releaseCallback = { [weak self] in
            Savant.control().disconnect()
            if let indexPath = self?.currentIndexPath() {
                self?.connectionDelegate?.showConnectButton(indexPath)
            }
            self?.currentHostId = nil
        }
    }

    func handleButtonAtIndexPath(indexPath: NSIndexPath) {
        var modelItem = itemForIndexPath(indexPath) as! HomePickerModelItem
        
        switch modelItem.cardType {
        case .Onboardable:
            onboardingHomes.insert(modelItem.system!.hostID)
            reloader?.reloadData()
        case .Onboarding:
            if let system = modelItem.system {
                self.currentHostId = system.hostID
                
                if let indexPath = self.currentIndexPath() {
                    self.connectionDelegate?.showProgressSpinner(true, indexPath: indexPath)
                }
                
                Savant.cloud().onboardSystem(system) { (success, error) in
                    if success {
                        Savant.control().connectToSystem(system)
                    } else {
                        if let indexPath = self.currentIndexPath() {
                            self.connectionDelegate?.showProgressSpinner(false, indexPath: indexPath)
                        }
                        
                        SCUAlertView(error: error).show()
                    }
                }
            }
        default:
            currentHostId = modelItem.system?.hostID
            
            if let indexPath = currentIndexPath() {
                connectionDelegate?.showProgressSpinner(true, indexPath: indexPath)
            }
            
            if let system = modelItem.system {
                Savant.control().connectToSystem(system)
            }
        }
    }
    
    func connectionDidConnect() {
        if let indexPath = currentIndexPath() {
            connectionDelegate?.showConnectButton(indexPath)
        }
    }
    
    func connectionDidFail() {
        if let indexPath = currentIndexPath() {
            connectionDelegate?.showConnectButton(indexPath)

            if let modelItem = itemForIndexPath(indexPath) as? HomePickerModelItem where modelItem.cardType != .HostNotFound {
                Savant.discovery().update()
            }
        }
    }
    
    func progressDidUpdate(progress: CGFloat) {
        if let indexPath = currentIndexPath() {
            connectionDelegate?.updateProgressStatusBar(progress, indexPath: indexPath)
        }
    }
}

