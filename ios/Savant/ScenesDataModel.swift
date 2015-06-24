//
//  ScenesDataModel.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator
import DataSource

class ScenesDataModel: DataSource, StateDelegate, DISResultDelegate {

    let coordinator: CoordinatorReference<InterfaceState>
    let generator = SAVDISRequestGenerator(app: "dashboard")
    var scenes = [SAVScene]()
    var feedbackNames: [String]!
    var roomFilter: SAVRoom?
    var fetchCallback: ((SAVScene)->Void)?

    weak var delegate: ScenesDataModelDelegate?
    weak var currentDialog: SCUSceneCreationDialog?

    init(coordinator c: CoordinatorReference<InterfaceState>) {
        coordinator = c
        super.init()
    }

    override func willAppear() {
        feedbackNames = generator.feedbackStringsWithStateNames(["scenes", "sceneSettings"]) as? [String]
        Savant.states().registerForStates(feedbackNames, forObserver: self)
        Savant.control().addDISResultObserver(self, forApp: "dashboard")
    }

    override func willDisappear() {
        unregisterImageObservers()
        sections.removeAll(keepCapacity: false)
        Savant.states().unregisterForStates(feedbackNames, forObserver: self)
        Savant.control().removeDISResultObserver(self, forApp: "dashboard")
        feedbackNames = nil
        fetchCallback = nil
    }

    // MARK: - Data Management

    func loadScenes(scenes s: [[NSObject : AnyObject]]) {
        unregisterImageObservers()

        scenes = map(s) {
            SAVScene(settings: $0)
        }

        sections = parse()
        reloader?.reloadData()
    }

    func filterScenes(room: SAVRoom?) {
        roomFilter = room
        sections = parse()
        reloader?.reloadData()
    }

    func parse() -> [Section] {
        var filteredScenes = scenes
        if let room = roomFilter {
            filteredScenes = filter(scenes) {
                $0.tags.containsObject(room.roomId)
            }
        }

        var items = map(filteredScenes) { (scene: SAVScene) -> ModelItem in
            let modelItem = ModelItem()
            modelItem.title = scene.name
            modelItem.dataObject = scene

            // TODO: These should be blurred directly from the SAVScene.
            modelItem.image = scene.blurredImage
            scene.imageChangeCallback = { [unowned self] image, blurredImage in
                modelItem.image = blurredImage
                self.reloader?.reloadData()
            }

            return modelItem
        }

        if items.count == 0 {
            let modelItem = ModelItem()
            modelItem.type = 1

            if let filter = roomFilter {
                modelItem.title = String(format: NSLocalizedString("No scenes in %@", comment: ""), filter.roomId)
            } else {
                modelItem.title = NSLocalizedString("No Scenes", comment: "")
            }

            items = [modelItem]
        }

        return [Section(modelItems: items)]
    }

    private func unregisterImageObservers() {
        for s in scenes {
            s.imageChangeCallback = nil
        }
    }

    override func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {
        if let scene = sceneForIndexPath(indexPath) {
            let activateSceneRequest = generator.request("ApplyScene", withArguments: ["id": scene.identifier])
            Savant.control().sendMessage(activateSceneRequest)
        }
    }

    func sceneForIndexPath(indexPath: NSIndexPath) -> SAVScene? {
        var scene: SAVScene?
        if let modelItem = itemForIndexPath(indexPath), dataObject = modelItem.dataObject as? SAVScene {
            scene = dataObject
        }
        return scene
    }

    // MARK: - DIS Interactions

    func addScene() {
        if let delegate = delegate {
            currentDialog = delegate.presentSceneCreationDialog()
            currentDialog?.startCaptureCallback = { [unowned self] in
                let captureRequest = self.generator.request("CaptureScene", withArguments: nil)
                Savant.control().sendMessage(captureRequest)
            }
        }
    }

    func saveScene(scene: SAVScene) {
        let request: SAVDISRequest

        if scene.identifier != nil {
            request = generator.request("UpdateScene", withArguments: scene.dictionaryRepresentation())
        } else {
            request = generator.request("CreateScene", withArguments: scene.dictionaryRepresentation())
        }

        Savant.control().sendMessage(request)
    }

    func startEditingIndexPath(indexPath: NSIndexPath) {
        if let scene = sceneForIndexPath(indexPath) {
            let fetchRequest = generator.request("FetchScene", withArguments: ["id": scene.identifier])
            Savant.control().sendMessage(fetchRequest)

            fetchCallback = { [unowned self] scene in
                if let delegate = self.delegate {
                    delegate.editScene(scene)
                }
            }
        }
    }

    // MARK: - DIS Result Delegate

    func disRequestDidCompleteWithResults(results: SAVDISResults!) {
        let scene = SAVScene(settings: results.results as! [NSObject: AnyObject])

        if results.request == "CaptureScene" {
            currentDialog?.captureCompleteWithScene(scene)
            scene.wasCaptured = true
        } else if results.request == "FetchScene" {
            if let fetchCallback = fetchCallback {
                fetchCallback(scene)
                self.fetchCallback = nil
            }
        }
    }

    // MARK: - State Feedback

    func didReceiveDISFeedback(feedback: SAVDISFeedback!) {
        if feedback.stateName() == "scenes" {
            if let value = feedback.value as? [[NSObject : AnyObject]] {
               loadScenes(scenes: value)
            }
        }
    }
}

protocol ScenesDataModelDelegate: class {
    func presentSceneCreationDialog() -> SCUSceneCreationDialog
    func editScene(scene: SAVScene)
}

