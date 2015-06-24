//
//  HomeUserPickerDataModel.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class HomeUserPickerDataModel: DataSource {

    let coordinator: CoordinatorReference<HomePickerState>

    init(coordinator c: CoordinatorReference<HomePickerState>, users: [SAVLocalUser]) {
        coordinator = c
        super.init()
        setItems(parse(users))
    }

    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        if let user = modelItem.dataObject as? SAVLocalUser {
            if Savant.control().userRequiresAuthentication(user.accountName) {
                if Savant.control().hasSavedPasswordForUser(user.accountName) {
                    Savant.control().loginToLocalUserWithSavedPassword(user.accountName)
                } else {
                    coordinator.transitionToState(.Authentication(user))
                }
            } else {
                Savant.control().loginToLocalUser(user.accountName, password: "")
            }
        }
    }

}

private func parse(users: [SAVLocalUser]) -> [ModelItem] {
    let items: [ModelItem]

    if users.count > 0 {
        items = map(users, { user in
            let modelItem = ModelItem()
            modelItem.dataObject = user
            modelItem.title = user.accountName
            
            if user.requiresAuthentication {
                modelItem.image = UIImage(named: "Security")?.scaleToSize(CGSize(width: Sizes.row * 3, height: Sizes.row * 3))
            }

            return modelItem
        })
    } else {
        let modelItem = ModelItem()
        modelItem.title = NSLocalizedString("No users are available", comment: "")
        items = [modelItem]
    }

    return items
}
