//
//  VerticalFlowLayout.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class ScenesCollectionController: ModelCollectionViewController, ScenesDataModelDelegate, SCUSceneCreationViewControllerDelegate {

    var scenesModel: ScenesDataModel!
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = Colors.color2shade1
        collectionView?.backgroundView = UIView()

        scenesModel.delegate = self

        self.navigationItem.titleView = prompt
        prompt.title.text = NSLocalizedString("Scenes", comment: "").uppercaseString
        navigationItem.leftBarButtonItem = backButtonForOrientation(UIDevice.interfaceOrientation())
        navigationItem.rightBarButtonItem = addButtonForOrientation(UIDevice.interfaceOrientation())

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "handleHold:")
        longPressGesture.minimumPressDuration = 0.5
        collectionView?.addGestureRecognizer(longPressGesture)
    }

    private func backButtonForOrientation(orientation: UIInterfaceOrientation) -> UIBarButtonItem {
        if UIDevice.isPhone() || UIInterfaceOrientationIsPortrait(orientation) {
            return UIBarButtonItem(image: UIImage(named: "ChevronBack"), style: .Plain, target: self, action: "goBack")
        } else {
            return UIBarButtonItem(image: UIImage(named: "ChevronBack"), style: .Plain, target: self, action: "goBack")
        }
    }

    private func addButtonForOrientation(orientation: UIInterfaceOrientation) -> UIBarButtonItem {
        if UIDevice.isPhone() || UIInterfaceOrientationIsPortrait(orientation) {
            return UIBarButtonItem(image: UIImage(named: "Add"), style: .Plain, target: self.scenesModel, action: "addScene")
        } else {
            return UIBarButtonItem(image: UIImage(named: "Add"), style: .Plain, target: self.scenesModel, action: "addScene")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let room = scenesModel.roomFilter?.roomId {
            prompt.prompt.text = room.uppercaseString
        } else {
            prompt.prompt.text = NSLocalizedString("Home", comment: "").uppercaseString
        }
    }

    func goBack() {
        scenesModel.coordinator.transitionBack()
    }

    override func viewDataSource() -> DataSource {
        return scenesModel
    }

    override func registerCells() {
        registerCell(type: 0, cellClass: SceneCell.self)
        registerCell(type: 1, cellClass: SceneCell.self)
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

                navigationItem.leftBarButtonItem = backButtonForOrientation(orientation)
                navigationItem.rightBarButtonItem = addButtonForOrientation(orientation)
            }

            layout.invalidateLayout()
        }
    }

    func handleHold(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .Ended {
            let point = recognizer.locationInView(collectionView)
            if let indexPath = collectionView?.indexPathForItemAtPoint(point) {
                scenesModel.startEditingIndexPath(indexPath)
            }
        }
    }

    // MARK: - Presentation

    func editScene(scene: SAVScene) {
        let creationVC = SCUSceneCreationViewController(state: .SelectedServicesList, andScene: scene)
        presentSceneViewController(creationVC)
    }

    func presentSceneCreationDialog() -> SCUSceneCreationDialog {
        let dialog = SCUSceneCreationDialog()

        dialog.sceneCallback = { action, scene in
            let creationVC: SCUSceneCreationViewController

            switch action {
            case .Capture:
                creationVC = SCUSceneCreationViewController(state: .Capture, andScene: scene)
            case .Create:
                creationVC = SCUSceneCreationViewController(state: .AddServicesList, andScene: scene)
            }

            self.presentSceneViewController(creationVC)
        }

        dialog.show()

        return dialog
    }

    func presentSceneViewController(viewController: SCUSceneCreationViewController) {
        viewController.delegate = self

        if UIDevice.isPad() {
            presentModal(viewController, animated: true)
        } else {
            presentViewController(viewController, animated: true, completion: nil)
        }
    }

    // MARK: - SCUSceneCreationViewControllerDelegate

    func saveScene(scene: SAVScene!) {
        scenesModel.saveScene(scene)
    }

    func viewControllerDismissedAnimated(animated: Bool) {
        dismissModal(animated)
    }

    // MARK: - Custom Modal Presentation (allows transparent background for iPads)

    var modalBackdrop: UIView?
    var modalVC: UIViewController?

    var presentConstraints: [NSLayoutConstraint] = []
    var dismissConstraints: [NSLayoutConstraint] = []

    func dismissModal(animated: Bool) {
        if let modalVC = modalVC {
            if animated {
                RootViewController.view.layoutIfNeeded()

                UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut, animations: {
                    RootViewController.view.removeConstraints(self.dismissConstraints)
                    }) { finished in
                        modalVC.sav_removeFromParentViewController()
                }
            } else {
                modalVC.sav_removeFromParentViewController()
            }
        }

        if let modalBackdrop = modalBackdrop {
            if animated {
                UIView.animateWithDuration(0.35, animations: {
                    modalBackdrop.alpha = 0
                    }) { finished in
                        modalBackdrop.removeFromSuperview()
                }
            } else {
                modalBackdrop.removeFromSuperview()
            }
        }
    }

    func presentModal(viewController: UIViewController, animated: Bool) {
        dismissModal(animated)

        if let backdropContainer = navigationController!.view {
            let backdrop = UIView()

            backdrop.backgroundColor = SCUColors.shared().color03

            backdropContainer.addSubview(backdrop)
            backdropContainer.sav_addFlushConstraintsForView(backdrop)

            if animated {
                backdrop.alpha = 0

                UIView.animateWithDuration(0.35) {
                    backdrop.alpha = 0.9
                }
            } else {
                backdrop.alpha = 0.9
            }

            modalBackdrop = backdrop
        }

        modalVC = viewController

        RootViewController.sav_addChildViewController(modalVC)
        RootViewController.view.sav_pinView(modalVC!.view, withOptions: .Horizontally)

        presentConstraints = NSLayoutConstraint.sav_constraintsWithMetrics(nil, views: ["view": modalVC!.view], formats: ["V:|[view]|"]) as! [NSLayoutConstraint]
        dismissConstraints = NSLayoutConstraint.sav_constraintsWithMetrics(nil, views: ["view": modalVC!.view], formats: ["view.height = super.height", "view.top = super.bottom"]) as! [NSLayoutConstraint]

        if animated {
            RootViewController.view.addConstraints(dismissConstraints)
            RootViewController.view.layoutIfNeeded()

            UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut, animations: {
                RootViewController.view.removeConstraints(self.dismissConstraints)
                RootViewController.view.addConstraints(self.presentConstraints)
                RootViewController.view.layoutIfNeeded()
                }, completion: nil)
        } else {
            RootViewController.view.addConstraints(self.presentConstraints)
        }
    }
}