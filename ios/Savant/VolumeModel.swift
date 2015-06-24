//
//  VolumeModel.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import SDK
import DataSource

enum VolumeModelCellType: Int {
    case Discrete = 0
    case Relative = 1
    case Master = 2
}

class VolumeModelItem: ModelItem {
    
    var master = false
    var status: VolumeStatus!
    var service: SAVService?
    
}

class VolumeStatus: Printable {
    var volume: Int = 0
    var muted: Bool = false
    var discreteAvailable: Bool = false
    
    var description: String {
        return "[vol:\(volume), m:\(muted), d:\(discreteAvailable)]"
    }
}

class VolumeModel: DataSource {
    
    private let serviceModel: ServiceModel
    private let roomContext: String?
    private var state = [String: VolumeStatus]()
    private var relevantRooms = [String: SAVService]()
    private let timer = SAVCoalescedTimer()
    private weak var backoffTimer: NSTimer?
    
    init(serviceModel sm: ServiceModel, roomContext rc: String?) {
        serviceModel = sm
        roomContext = rc
    }
    
    override func willAppear() {
        super.willAppear()
        Savant.states().addActiveServiceObserver(self)
        Savant.states().addVolumeObserver(self)
        
        if let rooms = Savant.data().allRoomIds() as? [String] {
            for room in rooms {
                var status = VolumeStatus()
                status.volume = Savant.states().volumeForRoom(room).integerValue
                status.muted = Savant.states().muteStatusForRoom(room)
                status.discreteAvailable = Savant.states().discreteVolumeStatusForRoom(room)
                state[room] = status
            }
        }
        
        if let services = Savant.states().activeServices() as? [SAVService] {
            for service in services {
                if serviceModel.serviceGroup.partiallyMatchesService(service) {
                    relevantRooms[service.zoneName!] = service
                }
            }
            
            updateRooms()
        }
    }
    
    override func willDisappear() {
        super.willDisappear()
        Savant.states().removeActiveServiceObserver(self)
        Savant.states().removeVolumeObserver(self)
    }
    
    func listenToSlider(slider: SCUSlider, indexPath: NSIndexPath) {
        slider.callback = {
            self.updateDiscreteVolume($0.value, indexPath: indexPath)
        }
    }
    
    private func updateDiscreteVolume(volume: CGFloat, indexPath: NSIndexPath) {
        if let item = itemForIndexPath(indexPath) as? VolumeModelItem, service = item.service {
            let request = SAVServiceRequest(service: service)
            request.request = "SetVolume"
            request.requestArguments = ["VolumeValue": volume]
            Savant.control().sendMessage(request)
            backoffTimer?.invalidate()
            backoffTimer = NSTimer.sav_scheduledBlockWithDelay(1.5) { [unowned self] in
                self.backoffTimer?.invalidate()
                self.backoffTimer = nil
                self.update()
            }
        }
    }
    
    func listenToButtons(#decrementButton: SCUButton, incrementButton: SCUButton, global: Bool, indexPath: NSIndexPath) {
        decrementButton.holdTime = 0.2
        incrementButton.holdTime = 0.2
        
        let decrementCallback = { [unowned self] in
            self.incDevVolume(command: "VolumeDown", global: global, indexPath: indexPath)
        }
        
        decrementButton.pressCallback = decrementCallback
        decrementButton.holdCallback = decrementCallback
        decrementButton.releaseCallback = decrementCallback
        
        let incrementCallback = { [unowned self] in
            self.incDevVolume(command: "VolumeUp", global: global, indexPath: indexPath)
        }
        
        incrementButton.pressCallback = incrementCallback
        incrementButton.holdCallback = incrementCallback
        incrementButton.releaseCallback = incrementCallback
    }
    
    private func incDevVolume(#command: String, global: Bool, indexPath: NSIndexPath) {
        if global {
            if let section = sectionForSection(0), items = section.items as? [VolumeModelItem] {
                for item in items {
                    if let service = item.service {
                        let request = SAVServiceRequest(service: service)
                        request.request = command
                        Savant.control().sendMessage(request)
                    }
                }
            }
        } else if let item = itemForIndexPath(indexPath) as? VolumeModelItem {
            if let service = item.service {
                let request = SAVServiceRequest(service: service)
                request.request = command
                Savant.control().sendMessage(request)
            }
        }
    }
    
    func listenToMuteButton(button: SCUButton, global: Bool, indexPath: NSIndexPath) {
        button.releaseCallback = { [unowned self] in
            self.toggleMute(global: global, indexPath: indexPath)
        }
    }
    
    private func toggleMute(#global: Bool, indexPath: NSIndexPath) {
        if let item = itemForIndexPath(indexPath) as? VolumeModelItem {
            let muted = item.status.muted
            let command: String
            
            if muted {
                command = "MuteOff"
            } else {
                command = "MuteOn"
            }
            
            if global {
                if let section = sectionForSection(0), items = section.items as? [VolumeModelItem] {
                    for item in items {
                        if let service = item.service where item.status.muted == muted {
                            let request = SAVServiceRequest(service: service)
                            request.request = command
                            Savant.control().sendMessage(request)
                        }
                    }
                }
            } else if let service = item.service{
                let request = SAVServiceRequest(service: service)
                request.request = command
                Savant.control().sendMessage(request)
            }
        }
    }
    
    private func updateRoom(room: String) {
        if relevantRooms[room] != nil {
            update()
        }
    }
    
    private func updateRooms() {
        /* Make a copy of relevantRooms and remove the current roomContext */
        var rRooms = relevantRooms
        
        if let roomContext = roomContext {
            rRooms.removeValueForKey(roomContext)
        }
        
        var items = map(sorted(rRooms.keys, stringSort()), { (room) -> VolumeModelItem in
            return self.volumeItemFromRoom(room)
        })
        
        if let room = roomContext {
            items.append(volumeItemFromRoom(room))
        }
        
        if count(items) > 1 {
            let item = VolumeModelItem()
            item.title = Strings.masterVolume
            item.master = true
            item.type = VolumeModelCellType.Master.rawValue
            item.status = VolumeStatus()
            items.append(item)
        }
        
        setItems(items)
        
        update()
    }
    
    private func volumeItemFromRoom(room: String) -> VolumeModelItem {
        let item = VolumeModelItem()
        item.title = room
        item.service = relevantRooms[room]
        
        if let status = self.state[room] {
            item.status = status
            
            if status.discreteAvailable {
                item.type = VolumeModelCellType.Discrete.rawValue
            } else {
                item.type = VolumeModelCellType.Relative.rawValue
            }
        }
        
        return item
    }
    
    private func update() {
        if backoffTimer != nil {
            return
        }
        
        if let reloader = reloader {
            timer.addWorkWithKey("reload") {
                
                /* Update global mute status */
                if let section = self.sectionForSection(0) {
                    if let items = section.items as? [VolumeModelItem] where count(items) > 1 {
                        let lastItem = items.last!
                        var its = items
                        its.removeLast()
                        var globalMute = true
                        
                        for item in its {
                            if !item.status.muted {
                                globalMute = false
                            }
                        }
                        
                        lastItem.status.muted = globalMute
                    }
                }
                
                reloader.reloadData()
            }
        }
    }

}

extension VolumeModel: VolumeObserver {
    
    func room(roomId: String, didUpdateVolume volume: NSNumber) {
        if let status = state[roomId] {
            status.volume = volume.integerValue
            updateRoom(roomId)
        }
    }
    
    func room(roomId: String, didUpdateMuteStatus muted: Bool) {
        if let status = state[roomId] {
            status.muted = muted
            updateRoom(roomId)
        }
    }
    
    func room(roomId: String, didUpdateDiscreteVolumeStatus discreteVolumeAvailable: Bool) {
        if let status = state[roomId] {
            status.discreteAvailable = discreteVolumeAvailable
            updateRoom(roomId)
        }
    }
    
}

extension VolumeModel: ActiveServiceObserver {
    
    func room(roomId: String, didUpdateActiveService service: SAVService?) {
        if let service = service {
            if serviceModel.serviceGroup.partiallyMatchesService(service) {
                relevantRooms[roomId] = service
                updateRooms()
            } else {
                if relevantRooms.removeValueForKey(roomId) != nil {
                    updateRooms()
                }
            }
        } else {
            if relevantRooms.removeValueForKey(roomId) != nil {
                updateRooms()
            }
        }
    }
    
}
