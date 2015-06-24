//
//  MicroInteractionAction.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import SDK

class MicroInteractionAction: SCUButton {
    
    private var normalTitle: String?
    private var normalImage: UIImage?

    private var toggleTitle: String?
    private var toggleImage: UIImage?

    private var activeCommand: String?
    private var normalCommand: String?
    private var toggleCommand: String?
    private var toggleState: String?

    private var registeredForState = false

    var actionHandler: ((command: String) -> ())?

    required init(image: UIImage?, command: String?, toggleImage tImage: UIImage?, toggleCommand tCommand: String?, toggleState tState: String?) {
        super.init(style: .Light, image: image)

        normalImage = image
        toggleImage = tImage
        normalCommand = command
        toggleCommand = tCommand
        toggleState = tState

        setup()
    }

    required init(title: String?, command: String?, toggleTitle tTitle: String?, toggleCommand tCommand: String?, toggleState tState: String?) {
        super.init(style: .Light, title: title)

        normalTitle = title
        toggleTitle = tTitle
        normalCommand = command
        toggleCommand = tCommand
        toggleState = tState

        setup()
    }

    override init(style: SCUButtonStyle) {
        super.init(style: style)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterStates()
    }

    func viewWillAppear() {
        registerStates()
    }

    func viewWillDisappear() {
        unregisterStates()
    }

    private func registerStates() {
        if !registeredForState {
            if let toggleState = toggleState {
                Savant.states().registerForStates([toggleState], forObserver: self)
            }
            registeredForState = true
        }
    }

    private func unregisterStates() {
        if registeredForState {
            if let toggleState = toggleState {
                Savant.states().unregisterForStates([toggleState], forObserver: self)
            }
            registeredForState = false
        }
    }

    private func setup() {
        backgroundColor = Colors.color1shade1
        selectedBackgroundColor = Colors.color3shade3
        selectedColor = Colors.color5shade1
        color = Colors.color5shade1

        activeCommand = normalCommand

        addTarget(self, action: "handleRelease:", forControlEvents: .TouchUpInside)
    }

    func handleRelease(button: SCUButton) {
        UIView.animateWithDuration(0.1, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 20, options: nil, animations: { [unowned self] in
            button.transform = CGAffineTransformMakeScale(0.98, 0.98)
            }, completion: { (finished: Bool) -> Void in
                UIView.animateWithDuration(0.1, animations: { [unowned self] in
                    self.transform = CGAffineTransformMakeScale(1, 1)
                    }, completion: { (finished: Bool) in
                        self.performAction()
                })
        })
    }

    func performAction() {
        if let actionHandler = actionHandler, activeCommand = activeCommand {
            actionHandler(command: activeCommand)
        }
    }
}

extension MicroInteractionAction: StateDelegate {
    func didReceiveStateUpdate(stateUpdate: SAVStateUpdate!) {
        if stateUpdate.state == toggleState {
            if (stateUpdate.value as! NSString).boolValue {
                activeCommand = toggleCommand

                if let toggleImage = toggleImage {
                    image = toggleImage
                }

                if let toggleTitle = toggleTitle {
                    title = toggleTitle
                }
            } else {
                activeCommand = normalCommand

                if let normalImage = normalImage {
                    image = normalImage
                }

                if let normalTitle = normalTitle {
                    title = normalTitle
                }
            }
        }
    }
}
