//
//  MicroInteractionPickerModel.swift
//  Prototype
//
//  Created by Stephen Silber on 3/16/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

enum PickerDirection:Int, Equatable {
    case Left = -1
    case Right = 1
    case None = 0
}

protocol MicroInteractionPickerDelegate: class {
    func updateRoomLabel(room: String, direction: PickerDirection)
}

class MicroInteractionPickerModel {
    
    weak var delegate: MicroInteractionPickerDelegate?
    var rooms: [String]!
    var currentIndex: Int?
    var currentRoom: String {
        get {
            return rooms[currentIndex!]
        }
    }
    
    required init(rooms: [String], delegate: MicroInteractionPickerDelegate?) {
        self.rooms = rooms
        self.delegate = delegate

        if (rooms.count != 0) {
            self.currentIndex = 0
            updateCurrentRoom(.None)
        }
    }
    
    func updateCurrentRoom(direction: PickerDirection) {

        if let index = currentIndex, rooms = rooms {
            if direction == .Right {
                if index + 1 < rooms.count {
                    currentIndex = index + 1
                } else {
                    currentIndex = 0
                }
            } else if direction == .Left {
                if index - 1 >= 0 {
                    currentIndex = index - 1
                } else {
                    currentIndex = rooms.count - 1
                }
            }

            delegate?.updateRoomLabel(rooms[currentIndex!], direction: direction)
        }
    }
}