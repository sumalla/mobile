//
//  ServiceModel.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import SDK

class ServiceModel {
    
    private let initialService: SAVService
    let serviceGroup: SAVServiceGroup
    let av: Bool
    let environmental: Bool
    let global: Bool
    let canPowerOff: Bool
    private var holdTimer: NSTimer?
    
    var service: SAVService? {
        if global {
            return activeServices.first
        } else {
            return initialService
        }
    }
    
    var activeServices: [SAVService] {
        if let activeServices = serviceGroup.activeServices as? [SAVService] {
            return activeServices
        } else {
            return [SAVService]()
        }
    }
    
    var powerCommands: [String] {
        if let service = service, commands = service.powerCommands as? [String] {
            return commands
        } else {
            return [String]()
        }
    }
    
    var volumeCommands: [String] {
        if let service = service, commands = service.volumeCommands as? [String] {
            return commands
        } else {
            return [String]()
        }
    }
    
    init(service: SAVService, global g: Bool) {
        if g {
            let mutableService = service.mutableCopy() as! SAVMutableService
            mutableService.zoneName = nil
            mutableService.variantId = nil
            initialService = mutableService.copy() as! SAVService
        } else {
            initialService = service
        }
        
        serviceGroup = SAVServiceGroup()
        serviceGroup.addService(service)
        environmental = service.serviceId!.hasPrefix("SVC_ENV")
        av = !environmental
        canPowerOff = av || service.serviceId! == "SVC_ENV_LIGHTING"
        global = g
    }
    
    func powerOnIfNecessary() {
        if !global && !environmental {
            if let currentService = service, room = currentService.zoneName {
                var powerOn = false
                
                if let activeService = Savant.states().activeServiceForRoom(room) {
                    if activeService != currentService {
                        powerOn = true
                    }
                } else {
                    powerOn = true
                }
                
                if powerOn {
                    self.sendCommand("PowerOn")
                }
                
            }
        }
    }
    
    func powerOff() {
        let command: String
        
        if let service = service, serviceId = service.serviceId where serviceId == "SVC_ENV_LIGHTING" {
            command = "__RoomLightsOff"
        } else {
            command = "PowerOff"
        }
        
        sendCommand(command)
    }
    
    func sendCommand(command: String, arguments: [NSObject: AnyObject]? = nil) {
        if command != "PowerOn" && (contains(powerCommands, command) || contains(volumeCommands, command)) {
            Savant.control().sendMessages(map(activeServices) { self.requestForService($0, command: command, arguments: arguments) })
        } else {
            if let service = service {
                Savant.control().sendMessage(requestForService(service, command: command, arguments: arguments))
            }
        }
    }
    
    func sendHoldCommand(command: String, arguments: [NSObject: AnyObject]? = nil, interval: NSTimeInterval = 0.25) {
        holdTimer?.invalidate()
        holdTimer = NSTimer.sav_scheduledTimerWithTimeInterval(interval, repeats: true) { [unowned self] in
            self.sendCommand(command, arguments: arguments)
        }
    }
    
    func endHoldWithCommand(command: String, arguments: [NSObject: AnyObject]? = nil) {
        holdTimer?.invalidate()
        self.sendCommand(command, arguments: arguments)
    }
    
    private func requestForService(service: SAVService, command: String, arguments: [NSObject: AnyObject]? = nil) -> SAVServiceRequest {
        let request = SAVServiceRequest(service: service)
        request.request = command
        request.requestArguments = arguments
        return request
    }

}
