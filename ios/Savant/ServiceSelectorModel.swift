//
//  ServiceSelectorModel.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

enum ServiceSelectorModelItemType {
    case NotNeeded
    case Lighting
    case Climate
    case AV
}

class ServiceSelectorModelItem: ModelItem {

    var enabled = false
    var modelType = ServiceSelectorModelItemType.NotNeeded
    var services = [SAVService]()
    var imageName = ""
    var supplementaryText = ""

}

class ServiceSelectorModel: DataSource {

    let room: SAVRoom?
    var registeredStates = [String]()
    var lightsAreOn = false
    var temperature = "--"
    var activeServices = [SAVService]()
    let updateTimer = SAVCoalescedTimer()
    var reloadOnAppear = false
    var isOnScreen = false

    init(room r: SAVRoom?) {
        room = r
        super.init()
        parseServices()
    }

    override func willAppear() {
        super.willAppear()

        if isOnScreen {
            return
        } else {
            isOnScreen = true
        }

        if registeredStates.count > 0 {
            Savant.states().registerForStates(registeredStates, forObserver: self)
        }

        Savant.states().addActiveServiceObserver(self)

        var activeServs: [SAVService]?
        if let room = room {
            activeServs = Savant.states().activeServiceListForRoom(room.roomId) as? [SAVService]
        } else {
            activeServs = Savant.states().activeServices() as? [SAVService]
        }

        if let activeServs = activeServs where activeServs != activeServices {
            reloadOnAppear = true
            activeServices = activeServs
        }
    }

    override func didAppear() {
        super.didAppear()

        if reloadOnAppear {
            reloadOnAppear = false
            reloader?.reloadData()
        }
    }

    override func willDisappear() {
        super.willDisappear()

        if isOnScreen {
            Savant.states().unregisterForStates(registeredStates, forObserver: self)
            Savant.states().removeActiveServiceObserver(self)

            isOnScreen = false
        }
    }

    func parseServices() {
        let services: [SAVService]

        if let room = room {
            services = serviceCache.valueForKey(room.roomId, defaultValue: [SAVService]())
        } else {
            services = serviceCache.valueForKey("home", defaultValue: [SAVService]())
        }

        var lightingService: SAVService?
        var shadeService: SAVService?
        var climateService: SAVService?
        var homeMonitorService: SAVService?

        let avServices = filter(services) { (service) in
            if let serviceId = service.serviceId {
                if serviceId.hasPrefix("SVC_AV") {
                    return true
                } else {
                    switch serviceId {
                    case "SVC_ENV_LIGHTING":
                        if self.room == nil || self.room!.hasLighting {
                            lightingService = service
                        }
                    case "SVC_ENV_SHADE":
                        if self.room == nil || self.room!.hasShades {
                            shadeService = service
                        }
                    case "SVC_ENV_HVAC":
                        if self.room == nil || self.room!.hasHVAC {
                            climateService = service
                        }
                    case "SVC_ENV_HOMEMONITOR":
                        homeMonitorService = service
                    default:
                        break
                    }
                }
            }

            return false
        }

        var groupedServices = groupBy(avServices) {
            SAVService.displayNameForServiceID($0.serviceId)
        }

        var modelItems = [ServiceSelectorModelItem]()
        var states = [String]()

        if let climateService = climateService {
            let cs: SAVService

            if let room = room {
                cs = SAVService(zone: room.roomId, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_HVAC")
                states.append("\(room.roomId).RoomCurrentTemperature")
            } else {
                cs = SAVService(zone: nil, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_HVAC")
                states.append("global.CurrentTemperature")
            }

            let item = parsedServiceItem(service: cs, services: [cs], type: .Climate)
            item.title = nil
            item.imageName = ""
            modelItems.append(item)
        }

        if let lightingService = lightingService {
            let ls: SAVService

            if let room = room {
                ls = SAVService(zone: room.roomId, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_LIGHTING")
                states.append("\(room.roomId).RoomLightsAreOn")
            } else {
                ls = SAVService(zone: nil, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_LIGHTING")
                states.append("global.LightsAreOn")
            }

            let item = parsedServiceItem(service: ls, services: [ls], type: .Lighting)
            modelItems.append(item)
        }

        if let shadeService = shadeService {
            let ss: SAVService

            if let room = room {
                ss = SAVService(zone: room.roomId, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_SHADE")
                states.append("\(room.roomId).RoomCurrentTemperature")
            } else {
                ss = SAVService(zone: nil, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_SHADE")
                states.append("global.CurrentTemperature")
            }

            let item = parsedServiceItem(service: ss, services: [ss], type: nil)
            modelItems.append(item)
        }
        
        if let homeMonitorService = homeMonitorService {
            let hms: SAVService
            
            if let room = room {
                hms = homeMonitorService
            } else {
                hms = SAVService(zone: nil, component: nil, logicalComponent: nil, variantId: nil, serviceId: "SVC_ENV_HOMEMONITOR")
            }
            
            let item = parsedServiceItem(service: hms, services: [hms], type: .AV)
            modelItems.append(item)
        }

        for service in sorted(groupedServices.keys) {
            if let services = groupedServices[service] where services.count > 0 {
                modelItems.append(parsedServiceItem(service: services.first!, services: services, type: .AV))
            }
        }
        setItems(modelItems)

        registeredStates = states
    }

    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        let modelItem = super.itemForIndexPath(indexPath)

        if let item = modelItem as? ServiceSelectorModelItem {
            switch item.modelType {
            case .Lighting:
                item.enabled = lightsAreOn
                break
            case .Climate:
                item.title = temperature
                break
            case .AV:
                var enabled = false

                for service in activeServices {
                    if contains(item.services, service) {
                        enabled = true
                        break
                    }
                }

                item.enabled = enabled
                break
            default:
                break
            }
        }

        return modelItem
    }

    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        if let item = modelItem as? ServiceSelectorModelItem {
            if item.services.count > 1 {
                let actions = ServiceSelectorActionSheet(services: item.services, room: room)
                actions.present()
            } else {
                interfaceCoordinator?.transitionToState(.Service(item.services.first!))
            }
        }
    }
    
    func serviceGroupsForIndexPath(indexPath: NSIndexPath) -> [SAVServiceGroup]? {
        let modelItem = itemForIndexPath(indexPath)
        if let item = modelItem as? ServiceSelectorModelItem {
            var serviceGroups: [String: SAVServiceGroup] = [:]
            for service in item.services {
                var group = serviceGroups[service.identifier!]
                if group == nil {
                    group = SAVServiceGroup()
                    serviceGroups[service.identifier!] = group
                }
                group?.addService(service)
            }

            return Array(serviceGroups.values)
        }
        
        return nil
    }

}

// MARK: - StateObservers

extension ServiceSelectorModel: StateDelegate, ActiveServiceObserver {

    func didReceiveStateUpdate(stateUpdate: SAVStateUpdate!) {
        if let stateName = stateUpdate.state {
            var reload = true

            if stateName.hasSuffix("CurrentTemperature") {
                temperature = stateUpdate.value as! String
            } else if stateName.hasSuffix("LightsAreOn") {
                lightsAreOn = (stateUpdate.value as! NSString).boolValue
            } else {
                reload = false
            }

            if reload {
                updateTimer.addWorkWithKey("refresh") {
                    reloader?.reloadData()
                }
            }
        }
    }

    func room(roomId: String, didUpdateActiveServiceList services: [AnyObject]) {
        var reload = false

        var activeServs: [SAVService]?

        if let room = room {
            if room.roomId == roomId {
                reload = true
                activeServs = services as? [SAVService]
            }
        } else {
            reload = true
            activeServs = Savant.states().activeServices() as? [SAVService]
        }

        if let activeServs = activeServs {
            activeServices = activeServs
        } else {
            activeServices.removeAll(keepCapacity: false)
        }

        if reload {
            updateTimer.addWorkWithKey("refresh") {
                reloader?.reloadData()
            }
        }
    }

}

// MARK: - Helpers

private func parsedServiceItem(#service: SAVService, #services: [SAVService], #type: ServiceSelectorModelItemType?) -> ServiceSelectorModelItem {
    let item = ServiceSelectorModelItem()
    item.supplementaryText = service.displayName
    item.imageName = service.iconName
    item.services = services

    if let type = type {
        item.modelType = type
    }

    return item
}
