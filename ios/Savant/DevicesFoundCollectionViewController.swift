//
//  DevicesFoundCollectionViewController.swift
//  Savant
//
//  Created by Stephen Silber on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class DevicesFoundCollectionViewController: FakeNavBarModelCollectionViewController, DevicesFoundViewDelegate {
    let coordinator:CoordinatorReference<DeviceOnboardingState>
    let model: DevicesFoundCollectionViewModel
    
    let doneButton = SCUButton(style: .PinnedButton)
    
    init(coordinator:CoordinatorReference<DeviceOnboardingState>, model: DevicesFoundCollectionViewModel) {
        self.coordinator = coordinator
        self.model = model
        let layout: FullscreenCardFlowLayout

        if UIDevice.isPad() {
            layout = FullscreenCardFlowLayout(interspace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4, width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 67)

        } else {
            layout = FullscreenCardFlowLayout(interspace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2, width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 40, height: Sizes.row * 55)
        }
        super.init(collectionViewLayout: layout)
        self.model.delegate = self
        self.model.reloader = self
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delaysContentTouches = false
        collectionView?.backgroundColor = UIColor.clearColor()
        collectionView?.backgroundView = UIView()
        
        doneButton.title = "Done"
        doneButton.target = self
        doneButton.releaseAction = "doneTapped"
        doneButton.titleLabel?.font = Fonts.caption1
        
        view.addSubview(doneButton)
        
        view.sav_pinView(doneButton, withOptions: .ToBottom | .Horizontally, withSpace: 0)
        view.sav_setHeight(Sizes.row * 8, forView: doneButton, isRelative: false)
        
        updateTitle()
    }
    
    override func reloadData() {
        super.reloadData()
        updateTitle()
    }
    
    func blinkLED(indexPath: NSIndexPath) {
        if let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? DeviceFoundCard {
            cell.blinkLED()
        }
    }
    
    func updateTitle() {
        if let deviceCount = self.model.numberOfItemsInSection(0) {
            if deviceCount == 1 {
                title = "Add \(self.model.numberOfItemsInSection(0)!) Device"
            } else {
                title = "Add \(self.model.numberOfItemsInSection(0)!) Devices"
            }
        }
    }
    
    func deviceSelected(device: ConfigurableProvisionableDevice) {
        coordinator.transitionToState(.RoomPicker(device: device))
    }
    
    func presentLightTypePicker(completion: (type: Int) -> ()) {
        let picker = SCUActionSheet(buttonTitles: [Strings.dimmer, Strings.switchString], cancelTitle: Strings.cancel)

        picker.callback =  { (index: Int) in
            completion(type: index)
        }
        
        picker.showInView(self.collectionView)
    }
    
    override func registerCells() {
        registerCell(type: 0, cellClass: DeviceFoundCard.self)
        registerCell(type: 1, cellClass: LightingDeviceFoundCard.self)
    }
    
    override func configure(#cell: UICollectionViewCell, indexPath: NSIndexPath) {
        if let cell = cell as? DeviceFoundCard {
            model.listenToSelectRoomButton(cell.mainButton, indexPath: indexPath)
            model.listenToLinkButton(cell.linkButton, indexPath: indexPath)
            model.listenToDeleteButton(cell.deleteButton, indexPath: indexPath)
            let tripleTap = UITapGestureRecognizer()
            tripleTap.numberOfTapsRequired = 3
            
            cell.textField.text = self.model.deviceNameForIndexPath(indexPath)
            
            tripleTap.sav_handler = { [unowned self] (state, point) in
                cell.textField.text = cell.showingUID ? self.model.deviceNameForIndexPath(indexPath) : self.model.uidForIndexPath(indexPath)
                cell.showingUID = !cell.showingUID
            }

            cell.addGestureRecognizer(tripleTap)

            cell.textField.textFieldUpdate = { (text: String, finishedEditing: Bool) in
                if finishedEditing {
                    self.model.updateDeviceName(text, indexPath: indexPath)
                }
            }
            
            cell.mainButtonText = self.model.roomNameForIndexPath(indexPath)
        }
        
        if let cell = cell as? LightingDeviceFoundCard {
            cell.lampModuleType = self.model.deviceLightingTypeForIndexPath(indexPath)
            model.listenToLightTypeButton(cell.lightingTypeButton, indexPath: indexPath)
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.animateInterfaceRotationChangeWithCoordinator(coordinator, block: { (orientation: UIInterfaceOrientation) -> Void in
            if let layout = self.collectionView?.collectionViewLayout as? FullscreenCardFlowLayout {
                layout.height = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.row * 65: Sizes.row * 67
                layout.width = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.columnForOrientation(orientation) * 32 : Sizes.columnForOrientation(orientation) * 30
                layout.interspace = UIInterfaceOrientationIsPortrait(orientation) ? Sizes.columnForOrientation(orientation) * 3 : Sizes.columnForOrientation(orientation) * 4
                layout.invalidateLayout()
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func viewDataSource() -> DataSource {
        return model
    }
    
    override func handleBack() {
        coordinator.transitionToState(.ConnectDevices)
    }
    
    func doneTapped() {
        let arr = model.devicesWithoutIgnored()
        coordinator.transitionToState(DeviceOnboardingState.Provisioning(devicesToProvision: arr))
    }
}
