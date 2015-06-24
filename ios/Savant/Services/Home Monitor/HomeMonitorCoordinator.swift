//
//  HomeMonitorCoordinator.swift
//  Savant
//
//  Created by Joseph Ross on 3/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

func NewHomeMonitorCoordinator() -> CoordinatorReference<HomeMonitorState> {
    return Coordinator(coordinatorManager: HomeMonitorCoordinatorManager())
}

func ==(lhs: HomeMonitorState, rhs: HomeMonitorState) -> Bool {
    return lhs.description == rhs.description
}

enum HomeMonitorState: Equatable, Printable {
    case List(SAVRoom?)
    case Detail(SAVService)
    case Live(SAVService)
    
    var service: SAVService? {
        get {
            switch self {
            case .Detail(let service):
                return service
            case .Live(let service):
                return service
            default:
                return nil
            }
        }
    }
    
    var room: SAVRoom? {
        get {
            switch self {
            case .List(let room):
                return room
            default:
                return nil
            }
        }
    }
    
    var description: String {
        get {
            switch self {
            case .Live(let service):
                return "Live: \(service.serviceString)"
            case .Detail(let service):
                return "Detail: \(service.serviceString)"
            case .List(let room):
                if let r = room {
                    return "List: \(r.roomId)"
                } else {
                    return "List"
                }
            }
        }
    }
}

class HomeMonitorCoordinatorManager: NSObject,CoordinatorManager {
    private override init() {}
    
    typealias StateType = HomeMonitorState
   
    weak var coordinator: CoordinatorReference<StateType>!

    var initialState: StateType { get {return .List(nil)}}
    
    func canTransition(#fromState: StateType, toState: StateType) -> Bool {
        return true
    }
    
    func transition(#fromState: StateType, toState: StateType) {
        
    }
}
