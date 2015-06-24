//
//  PopoverMicroInteractionController.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class PopoverMicroInteractionController : PopoverController, UIGestureRecognizerDelegate {
    
    private var actionsForOption = [String: [MicroInteractionAction]]()
    private var actions: [MicroInteractionAction] {
        get {
            return actionsForOption[currentOption]!
        }
    }

    private(set) var pickerOptions: [String]!
    private var pickerOptionsToService = [String: SAVService]()
    var currentOption: String {
        get {
            if showsPicker {
                return pickerView.currentValue
            } else {
                return pickerOptions.first!
            }
        }
    }
    
    private var pickerView: MicroInteractionPickerView!
    var showsPicker: Bool {
        get {
            return pickerOptions.count > 1
        }
    }
    private(set) var gesture: UIGestureRecognizer?
    private var serviceModel = SCUServiceViewModel()

    private var buttonView: UIView?
    private var visibleActions: [MicroInteractionAction]?

    private var columnWidth: CGFloat = 0
    private var columns: Int = 0
    private var fromFrame: CGRect = CGRectZero
    private var fromIndex: Int = 0

    required init?(serviceGroups s: [SAVServiceGroup]?, gesture: UILongPressGestureRecognizer?) {
        super.init()

        if let s = s {
            prepapreActionsForGroups(s)

            if pickerOptionsToService.count == 0 || actionsForOption.count == 0 {
                return nil
            }

            var options = Array(pickerOptionsToService.keys).sorted {
                let service0 = self.pickerOptionsToService[$0]!
                let service1 = self.pickerOptionsToService[$1]!

                if service0.zoneName == nil {
                    return true
                } else if service1.zoneName == nil {
                    return false
                } else {
                    return $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
                }
            }

            pickerOptions = options
        }

        self.gesture = gesture!
        
        gesture!.addTarget(self, action: "handlePan:")
        self.view.addGestureRecognizer(gesture!)

        if showsPicker {
            pickerView = MicroInteractionPickerView(rooms: pickerOptions)
            pickerView.delegate = self
            container.addSubview(pickerView)
            container.sav_pinView(pickerView, withOptions: .ToBottom, withSpace: 0)
            container.sav_pinView(pickerView, withOptions: .Horizontally, withSpace: 0)
        }

        container.backgroundColor = Colors.color3shade3

        updateButtons(nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func prepapreActionsForGroups(serviceGroups: [SAVServiceGroup]?) {
        var actionsPerGroup: [String: [MicroInteractionAction]] = [:]

        if let serviceGroups = serviceGroups {
            var activeGroups: [SAVServiceGroup] = []
            var oneRoomPerGroup = true

            for group in serviceGroups {
                // Ignore groups that are not active
                if group.serviceId.hasPrefix("SVC_AV_") && group.activeServices.count == 0 {
                    continue
                }

                if group.serviceId.hasPrefix("SVC_ENV_") {
                    // Get the rooms from database for ENV services
                    // TODO: Add special case for HVAC zones
                    let service = group.services.first! as! SAVService
                    if service.zoneName == nil {
                        let rooms = Savant.data().zonesWithService(service) as! [String]
                        for room in rooms {
                            var mutableService = service.mutableCopy() as! SAVMutableService
                            mutableService.zoneName = room

                            let model = SCUServiceViewModel(service: mutableService)

                            actionsForOption[room] = actionsForModel(model)
                            pickerOptionsToService[room] = mutableService
                        }
                    } else {
                        let model = SCUServiceViewModel(service: service)

                        actionsForOption[service.zoneName!] = actionsForModel(model)
                        pickerOptionsToService[service.zoneName!] = service
                    }
                } else {
                    let activeServices = group.activeServices
                    for service in activeServices as! [SAVService] {
                        if let zoneName = service.zoneName {
                            if !contains(pickerOptionsToService.keys, service.zoneName!) {
                                let model = SCUServiceViewModel(service: service)

                                actionsForOption[service.zoneName!] = actionsForModel(model)
                                pickerOptionsToService[service.zoneName!] = service
                            }
                        }
                    }

                    if activeServices.count > 1 {
                        oneRoomPerGroup = false
                    }
                }

                activeGroups.append(group)

                // Only care about one ENV service
                if group.serviceId.hasPrefix("SVC_ENV_") {
                    break
                }
            }

            // There are multiple devices
            if activeGroups.count > 1 {
                // at least one has multiple rooms, add device entries to control the groups
                if !oneRoomPerGroup {
                    for group in activeGroups {
                        var model = SCUServiceViewModel(service: group.wildCardedService)
                        model.servicesFirst = true

                        actionsForOption[group.alias] = actionsForModel(model)
                        pickerOptionsToService[group.alias] = group.wildCardedService
                    }
                }
            // There is only one device, and it has multiple rooms
            } else if pickerOptionsToService.count > 1 {
                let wildCardedService = activeGroups.first!.wildCardedService
                var model = SCUServiceViewModel(service: wildCardedService)
                model.servicesFirst = true

                actionsForOption["Whole Home"] = actionsForModel(model)
                pickerOptionsToService["Whole Home"] = wildCardedService
            }
        }
    }

    func updateButtons(completion: (() -> ())?) {
        let configuration = SAVViewDistributionConfiguration()
        configuration.fixedHeight = Sizes.row * 12
        configuration.distributeEvenly = true
        configuration.interSpace = UIScreen.screenPixel() * 1

        var frameChanged = false
        if let visibleActions = visibleActions {
            for action in visibleActions {
                action.viewWillDisappear()
            }

            // TODO: handle this better
            // when frame is changing, marquee animation messes up
            if visibleActions.count != actions.count {
                frameChanged = true
            }
        }

        visibleActions = actions

        if visible {
            for action in actions {
                action.viewWillAppear()
            }
        }

        if let buttonView = buttonView {
            buttonView.removeFromSuperview()
        }

        buttonView = UIView.sav_viewWithEvenlyDistributedViews(actions, withConfiguration: configuration)
        container.addSubview(buttonView!)
        container.sav_pinView(buttonView, withOptions: .ToTop | .Horizontally, withSpace: 0)

        if showsPicker {
            container.bringSubviewToFront(pickerView)
        }

        if frameChanged || !visible {
            let direction: IndicatorDirection = isRectOnTopHalfOfView(fromFrame, view: RootViewController.view) ? .Top : .Bottom

            var indicatorOrigin: CGFloat = 0
            var frame = CGRectZero
            frame.size = self.contentSize()
            frame.origin.y = direction == .Bottom ? CGRectGetMinY(fromFrame) - CGRectGetHeight(frame) - Sizes.row : CGRectGetMaxY(fromFrame) - Sizes.row * 4

            // Calculate for the simple case, where the buttons fill the screen
            if CGRectGetWidth(UIScreen.mainScreen().bounds) < columnWidth * CGFloat(actions.count + 1) {
                // Center the buttons on the screen
                frame.origin.x = CGRectGetMidX(fromFrame) - (columnWidth / 2) - (columnWidth * CGFloat(fromIndex))

                // Place the indicator about the from view
                indicatorOrigin = CGRectGetMidX(fromFrame) - CGRectGetMinX(frame)
            } else {
                // Center the buttons above the from view
                frame.origin.x = CGRectGetMidX(fromFrame) - CGRectGetWidth(frame) / 2

                // For even numbers of buttons, shift frame half a button towards the closest edge
                // so it the from button is not between buttons
                var originOffset: CGFloat = 0
                if actions.count % 2 == 0 {
                    if (fromIndex + 1) > columns / 2 {
                        originOffset = buttonWidth() / 2
                    } else {
                        originOffset = -(buttonWidth() / 2)
                    }
                }

                frame.origin.x += originOffset

                var columnOffset: CGFloat = 0
                // If buttons are off the right side of screen, shift left until they are all visible
                while CGRectGetMaxX(frame) > CGRectGetMaxX(UIScreen.mainScreen().bounds) {
                    frame.origin.x -= columnWidth
                }

                // If buttons are off the right left of screen, shift right until they are all visible
                while CGRectGetMinX(frame) < CGRectGetMinX(UIScreen.mainScreen().bounds) {
                    frame.origin.x += columnWidth
                }


                // Place the indicator at the center
                indicatorOrigin = CGRectGetWidth(frame) / 2 + originOffset
                while indicatorOrigin + CGRectGetMinX(frame) < CGRectGetMinX(fromFrame) {
                    indicatorOrigin += columnWidth;
                }
                while indicatorOrigin + CGRectGetMinX(frame) > CGRectGetMaxX(fromFrame) {
                    indicatorOrigin -= columnWidth;
                }
            }

            if frameChanged {
                UIView.animateWithDuration(0.1, animations: {
                    self.view.frame = frame
                    self.drawIndicator(indicatorOrigin, direction: direction)
                    }) { finished in
                        if let completion = completion {
                            completion()
                        }
                }
            } else {
                view.frame = frame
                drawIndicator(indicatorOrigin, direction: direction)
            }
        } else if let completion = completion {
            completion()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        for action in actions {
            action.viewWillAppear()
        }
        visible = true
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for action in actions {
            action.viewWillDisappear()
        }
        visible = false
    }
    
    override func contentSize() -> CGSize {
        var width = columnWidth * CGFloat(actions.count)

        // If buttons don't fit on screen, shrink width to max size
        if width > CGRectGetWidth(UIScreen.mainScreen().bounds) {
            width = floor(CGRectGetWidth(UIScreen.mainScreen().bounds) / columnWidth) * columnWidth
        }

        if self.showsPicker {
            return CGSizeMake(width, buttonHeight() + self.pickerView.intrinsicContentSize().height)
        } else {
            return CGSizeMake(width, buttonHeight())
        }
    }

    func buttonHeight() -> CGFloat {
        return min(columnWidth, Sizes.row * 12)
    }

    func buttonWidth() -> CGFloat {
        return contentSize().width / CGFloat(actions.count)
    }
    
    func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            break
        case .Changed:
            if CGRectContainsPoint(container.frame, gesture.locationInView(container)) {
                for action in actions {
                    if CGRectContainsPoint(action.bounds, gesture.locationInView(action)) {
                        UIView.animateWithDuration(0.2) {
                            action.backgroundColor = Colors.color3shade4
                        }
                    } else {
                        UIView.animateWithDuration(0.2) {
                            action.backgroundColor = Colors.color1shade1
                        }
                    }
                }
            } else {
                for action in actions {
                    if action.backgroundColor != Colors.color1shade1 {
                        action.backgroundColor = Colors.color1shade1
                    }
                }
            }
            break
        case .Ended:
            fallthrough
        case .Cancelled:
            self.gesture?.enabled = false
            self.gesture?.enabled = true
            
            if CGRectContainsPoint(container.frame, gesture.locationInView(container)) {
                for action in actions {
                    if CGRectContainsPoint(action.bounds, gesture.locationInView(action)) {
                        action.backgroundColor = Colors.color1shade1

                        action.performAction()
                        break
                    }
                }
            }
            
            gesture.removeTarget(self, action: "handlePan:")
            view.removeGestureRecognizer(gesture)

            self.completionBlock?()

            break
        default:
            break
        }
    }

    override internal func showFromView(fromView: UIView, index: Int, columns: Int, columnWidth: CGFloat, completionClosure: (() ->())?) {
        if let completionClosure = completionClosure {
            self.completionBlock = completionClosure
        }

        self.fromIndex = index
        self.fromFrame = fromView.convertRect(fromView.bounds, toView: RootViewController.view)
        self.columnWidth = columnWidth
        self.columns = columns

        updateButtons(nil)

        RootViewController.presentViewController(self, animated: true, completion: nil)
    }
}

extension PopoverMicroInteractionController: MicroInteractionPickerViewDelegate {
    func pickerWillSwitchToRoom(room: String, completion: () -> ()) {
        updateButtons(completion)
    }
}

private extension PopoverMicroInteractionController {
    private func actionsForModel(model: SCUServiceViewModel) -> ([MicroInteractionAction])? {
        var actions = [MicroInteractionAction]()

        if model.service == nil {
            return nil
        }

        let serviceId = model.service.serviceId

        if let serviceId = serviceId {
            if serviceId.hasPrefix("SVC_AV_") {
                actions = avActions(model)
            } else if serviceId.hasPrefix("SVC_ENV_HVAC") {
                actions = hvacActions(model)
            } else if serviceId.hasPrefix("SVC_ENV_LIGHTING") {
                actions = lightingActions(model)
            } else {
                actions = lightingActions(model)
            }
        }

        return actions
    }

    private func lightingActions(model: SCUServiceViewModel) -> ([MicroInteractionAction]) {
        let power = action(imageName: "Power", command: "__RoomLightsOff", autoDismiss: true, arguments: nil, model: model)
        let plus  = action(imageName: "BrightnessUp", command: "__RoomSetBrightness", autoDismiss: true, arguments: ["BrightnessLevel": "100"], model: model)
        let minus = action(imageName: "BrightnessDown", command: "__RoomSetBrightness", autoDismiss: true, arguments: ["BrightnessLevel": "50"], model: model)
        return [power, plus, minus]
    }

    private func hvacActions(model: SCUServiceViewModel) -> ([MicroInteractionAction]) {
        let minus = action(title: "-", command: "VolumeMinus", autoDismiss: false, arguments: nil, model: model)
        let plus  = action(title: "+", command: "VolumePlus", autoDismiss: false, arguments: nil, model: model)
        let power = action(imageName: "Power", command: "Power", autoDismiss: true, arguments: nil, model: model)
        return [minus, plus, power]
    }

    private func avActions(model: SCUServiceViewModel) -> ([MicroInteractionAction]) {
        var interactions: [MicroInteractionAction] = []

        // Volume
        interactions.append(action(imageName: "Power", command: "PowerOff", autoDismiss: true, arguments: nil, model: model))

        let muteState: String
        if model.serviceGroup.activeServices.count > 1 {
            var scopePart = model.service.connectorId
            if scopePart == nil {
                scopePart = model.service.logicalComponent
            }
            muteState = String(format:"%@.%@.isMuted", model.service.component!, scopePart!)
        } else {
            muteState = model.service.zoneName!.stringByAppendingString(".IsMuted")
        }

        interactions.append(action(imageName: "volumeMute", toggleImageName: "Unmute", toggleState: muteState, autoDismiss: false, command: "MuteOn", toggleCommand: "MuteOff", arguments: nil, model: model))

        for type in transportButtons(model.serviceGroup) {
            switch type {
            case .PlayPause(let playCommand, let pauseCommand, let toggleState):
                interactions.append(action(imageName: "Pause", toggleImageName: "Play", toggleState: model.serviceGroup.stateScope.stringByAppendingString(".CurrentPauseStatus"), autoDismiss: false, command: "Pause", toggleCommand: "Play", arguments: nil, model: model))
                break
            case .Pause(let command):
                interactions.append(action(imageName: "Pause", command: command, autoDismiss: false, arguments: nil, model: model))
                break
            case .Play(let command):
                interactions.append(action(imageName: "Play", command: command, autoDismiss: false, arguments: nil, model: model))
                break
            case .SkipUp(let command):
                interactions.append(action(imageName: "Next", command: command, autoDismiss: false, arguments: nil, model: model))
                break
            case .ScanUp(let command):
                interactions.append(action(imageName: "FastForward", command: command, autoDismiss: false, arguments: nil, model: model))
                break
            case .PlayPauseStatic(let command):
                interactions.append(action(imageName: "PlayPause", command: command, autoDismiss: false, arguments: nil, model: model))
                break
            }
        }
        
        return interactions
    }

    private func action(#imageName: String?, command: String, autoDismiss: Bool, arguments: [String: String]?, model: SCUServiceViewModel) -> MicroInteractionAction {
        return action(imageName: imageName, toggleImageName: nil, toggleState: nil, autoDismiss: autoDismiss, command: command, toggleCommand: nil, arguments: arguments, model: model)
    }

    private func action(#imageName: String?, toggleImageName: String?, toggleState: String?, autoDismiss: Bool, command: String, toggleCommand: String?, arguments: [String: String]?, model: SCUServiceViewModel) -> MicroInteractionAction {
        var image: UIImage?
        var toggleImage: UIImage?

        if let imageName = imageName {
            image = UIImage(named: imageName)
        }

        if let toggleImageName = toggleImageName {
            toggleImage = UIImage(named: toggleImageName)
        }

        let action = MicroInteractionAction(image: image, command: command, toggleImage: toggleImage, toggleCommand: toggleCommand, toggleState: toggleState)

        action.actionHandler = { [unowned self] (command: String) in
            let sendCommand: () -> () = {
                if let args = arguments {
                    model.sendCommand(command, withArguments: args)
                } else {
                    model.sendCommand(command)
                }
            }

            if autoDismiss {
                self.dismissViewControllerAnimated(true, completion: sendCommand)
            } else {
                sendCommand()
            }
        }

        return action
    }

    private func action(#title: String?, command: String, autoDismiss: Bool, arguments: [String: String]?, model: SCUServiceViewModel) -> MicroInteractionAction {
        return action(title: title, toggleTitle: nil, toggleState: nil, autoDismiss: autoDismiss, command: command, toggleCommand: nil, arguments: arguments, model: model)
    }

    private func action(#title: String?, toggleTitle: String?, toggleState: String?, autoDismiss: Bool, command: String, toggleCommand: String?, arguments: [String: String]?, model: SCUServiceViewModel) -> MicroInteractionAction {
        let action = MicroInteractionAction(title: title, command: command, toggleTitle: toggleTitle, toggleCommand: toggleCommand, toggleState: toggleState)

        action.actionHandler = { [unowned self] (command: String) in
            let sendCommand: () -> () = {
                if let args = arguments {
                    model.sendCommand(command, withArguments: args)
                } else {
                    model.sendCommand(command)
                }
            }

            if autoDismiss {
                self.dismissViewControllerAnimated(true, completion: sendCommand)
            } else {
                sendCommand()
            }
        }
        
        return action
    }

    private func transportButtons(serviceGroup: SAVServiceGroup) -> [TransportButtonType] {
        var transportButtons: [TransportButtonType] = []
        let serviceId = serviceGroup.serviceId as NSString

        if serviceId.containsString("LIVEMEDIAQUERY") || serviceId.isEqualToString("SVC_AV_DIGITIALAUDIO") {
            transportButtons.append(.PlayPause(playCommand: "Play", pauseCommand: "Pause", toggleState: ""))
            transportButtons.append(.SkipUp(command: "SkipUp"))
        } else {
            if serviceGroup.serviceId.hasPrefix("SVC_AV_APPLEREMOTEMEDIASERVER") {
                transportButtons.append(.PlayPauseStatic(command: "PlayPause"))
            } else {
                let transportCommands: [String] = serviceGroup.services.first!.transportCommands as! [String]
                if contains(transportCommands, "Pause") {
                    transportButtons.append(.Pause(command: "Pause"))
                }

                if contains(transportCommands, "Play") {
                    transportButtons.append(.Play(command: "Play"))
                }

                if contains(transportCommands, "SkipUp") {
                    transportButtons.append(.SkipUp(command: "SkipUp"))
                } else {
                    var command: String?

                    if contains(transportCommands, "ScanUp") {
                        command = "ScanUp"
                    } else if contains(transportCommands, "FastForward") {
                        command = "FastForward"
                    } else if contains(transportCommands, "FastPlayForward") {
                        command = "FastPlayForward"
                    }

                    if let command = command {
                        transportButtons.append(.ScanUp(command: command))
                    }
                }
            }
        }
        
        return transportButtons
    }
}

private enum TransportButtonType {
    case PlayPause(playCommand: String, pauseCommand: String, toggleState: String)
    case Pause(command: String)
    case Play(command: String)
    case SkipUp(command: String)
    case ScanUp(command: String)

    // Apple TV only
    case PlayPauseStatic(command: String)
}
