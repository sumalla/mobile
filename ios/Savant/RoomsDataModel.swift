//
//  RoomsDataModel.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class RoomsItemModel: ModelItem {
    var serviceSelector: ServiceSelectorViewController?
    var view: UIView?
}

class RoomsDataModel: DataSource {

    let coordinator: CoordinatorReference<InterfaceState>
    let rooms: [SAVRoom]
    var imageObservers = [String: AnyObject]()

    init(coordinator c: CoordinatorReference<InterfaceState>) {
        coordinator = c

        if let rooms = Savant.data().allRooms() as? [SAVRoom] {
            self.rooms = rooms
        } else {
            rooms = [SAVRoom]()
        }

        super.init()

        if rooms.count > 0 {
            setItems(parse(rooms))
        }
    }

    override func willDisappear() {
        super.willDisappear()

        if let section = sectionForSection(0) {
            for item in section.items {
                if let item = item as? RoomsItemModel, ss = item.serviceSelector {
                    ss.viewWillDisappear(false)
                    ss.viewDidDisappear(false)
                }
            }
        }

        for observer in imageObservers.values {
            Savant.images().removeObserver(observer)
        }

        imageObservers.removeAll(keepCapacity: false)
    }

    override func willAppear() {
        super.willAppear()

        if let section = sectionForSection(0) {
            for item in section.items {
                if let item = item as? RoomsItemModel, ss = item.serviceSelector {
                    ss.viewWillAppear(false)
                    ss.viewDidAppear(false)
                }
            }
        }
    }

    func parse(rooms: [SAVRoom]) -> [ModelItem] {
        return map(rooms) { (room: SAVRoom) in
            let modelItem = RoomsItemModel()
            modelItem.title = room.roomId
            modelItem.dataObject = room
            return modelItem
        }
    }

    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        if let room = modelItem.dataObject as? SAVRoom {
            coordinator.transitionToState(.Room(room))
        }
    }

    func indexOfRoom(room: SAVRoom) -> NSIndexPath? {
        if let found = find(rooms, room) {
            return NSIndexPath(forItem: found, inSection: 0)
        }

        return nil
    }

    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        let item = super.itemForIndexPath(indexPath)

        if let item = item as? RoomsItemModel {
            if item.serviceSelector == nil {
                if let room = item.dataObject as? SAVRoom {
                    let layout = SCUPagingHorizontalFlowLayout()
                    layout.numberOfColums = 4

                    if UIDevice.isPad() {
                        if UIInterfaceOrientationIsPortrait(UIDevice.interfaceOrientation()) {
                            layout.numberOfColums = 5
                        }
                        
                        layout.interSpace = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
                        layout.pageInset = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
                    } else {
                        layout.interSpace = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
                        layout.pageInset = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
                    }

                    let serviceSelector = ServiceSelectorViewController(collectionViewLayout: layout)
                    serviceSelector.compact = true
                    serviceSelector.model = ServiceSelectorModel(room: room)
                    serviceSelector.viewWillAppear(false)
                    serviceSelector.viewDidAppear(false)
                    item.serviceSelector = serviceSelector
                    item.view = serviceSelector.collectionView
                }
            }
        }

        createObserverIfNecessaryForIndexPath(indexPath)
        createObserverIfNecessaryForIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section))
        createObserverIfNecessaryForIndexPath(NSIndexPath(forRow: indexPath.row + 2, inSection: indexPath.section))
        
        return item
    }

    private func createObserverIfNecessaryForIndexPath(indexPath: NSIndexPath) {
        let item = super.itemForIndexPath(indexPath)

        if let item = item, room = item.dataObject as? SAVRoom {
            if imageObservers[room.roomId] == nil {
                let observer: AnyObject! = Savant.images().addObserverForKey(room.roomId, type: .RoomImage, size: .Large, blurred: false) { [unowned self] image, isDefault in
                    item.image = image
                    self.reloader?.reloadIndexPaths([indexPath], animation: .None)
                }

                imageObservers[room.roomId] = observer
            }
        }
    }
}
