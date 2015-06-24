//
//  DevicesCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class DevicesCollectionController: ModelCollectionViewController {

    var devicesModel: DevicesDataModel!
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = prompt
        prompt.title.text = NSLocalizedString("Devices", comment: "").uppercaseString
        navigationItem.rightBarButtonItem = forwardButtonForOrientation(UIDevice.interfaceOrientation())
        navigationItem.leftBarButtonItem = addButtonForOrientation(UIDevice.interfaceOrientation())
    }

    override func viewDataSource() -> DataSource {
        return devicesModel
    }

    private func forwardButtonForOrientation(orientation: UIInterfaceOrientation) -> UIBarButtonItem {
        if UIDevice.isPhone() || UIInterfaceOrientationIsPortrait(orientation) {
            return UIBarButtonItem(image: UIImage(named: "ChevronForward"), style: .Plain, target: self, action: "goBack")
        } else {
            return UIBarButtonItem(image: UIImage(named: "ChevronForward"), style: .Plain, target: self, action: "goBack")
        }
    }

    private func addButtonForOrientation(orientation: UIInterfaceOrientation) -> UIBarButtonItem {
        if UIDevice.isPhone() || UIInterfaceOrientationIsPortrait(orientation) {
            return UIBarButtonItem(image: UIImage(named: "Add"), style: .Plain, target: self, action: "addDevice")
        } else {
            return UIBarButtonItem(image: UIImage(named: "Add"), style: .Plain, target: self, action: "addDevice")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let room = devicesModel.roomFilter?.roomId {
            prompt.prompt.text = room.uppercaseString
        } else {
            prompt.prompt.text = NSLocalizedString("Home", comment: "").uppercaseString
        }
    }

    func goBack() {
        devicesModel.coordinator.transitionBack()
    }

    override func configureLayoutWithOrientation(orientation: UIInterfaceOrientation) {
        if let layout = self.collectionViewLayout as? VerticalFlowLayout {
            layout.interspace = Sizes.row / 2

            if UIDevice.isPhone() {
                layout.horizontalInset = 0
                layout.height = Sizes.row * 22
                layout.columns = 1
            } else {
                layout.height = Sizes.row * 25
                layout.horizontalInset = 0

                if UIInterfaceOrientationIsPortrait(orientation) {
                    layout.columns = 1
                } else {
                    layout.columns = 2
                    layout.horizontalInset = Sizes.columnForOrientation(orientation) * 2
                }

                navigationItem.rightBarButtonItem = forwardButtonForOrientation(orientation)
                navigationItem.leftBarButtonItem = addButtonForOrientation(orientation)
            }

            layout.invalidateLayout()
        }
    }
	
	internal func addDevice() {
		RootCoordinator.transitionToState(.DeviceOnboarding)
	}

}
