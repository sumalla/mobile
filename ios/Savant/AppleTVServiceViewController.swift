//
//  AppleTVServiceViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class AppleTVServiceViewController: ServiceViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeView = SCUSwipeView(frame: CGRectZero, configuration: .All)
        swipeView.delegate = self
        swipeView.backgroundColor = Colors.color1shade6
        contentView.addSubview(swipeView)
        contentView.sav_addFlushConstraintsForView(swipeView)
    }
    
    override func tabBarButtons() -> [ServiceTabBarButtonConfiguration]? {
        let menu = SCUButton(title: "Menu")
        menu.pressAction = "sendMenu"
        menu.holdAction = "sendMenu"
        
        let play = SCUButton(image: UIImage(named: "PlayPause"))
        play.pressAction = "sendPlay"
        play.holdAction = "sendPlay"
        
        for button in [menu, play] {
            button.releaseAction = "sendRelease"
            button.holdTime = 0.2
            button.target = self
        }
        
        return [volumeTabBarButton, ServiceTabBarButtonConfiguration(button: menu), ServiceTabBarButtonConfiguration(button: play)]
    }
    
    func sendMenu() {
        serviceModel.sendCommand("Menu")
    }
    
    func sendPlay() {
        serviceModel.sendCommand("Play")
    }
    
    func sendRelease() {
        serviceModel.endHoldWithCommand("StopRepeat")
    }

}

extension AppleTVServiceViewController: SCUSwipeViewDelegate {
    
    func swipeView(swipeView: SCUSwipeView!, didReceiveInteraction interaction: SCUSwipeViewDirection, isHold: Bool) {
        var command: String?
        
        switch interaction {
        case SCUSwipeViewDirection.Up:
            command = "OSDCursorUp"
        case SCUSwipeViewDirection.Down:
            command = "OSDCursorDown"
        case SCUSwipeViewDirection.Left:
            command = "OSDCursorLeft"
        case SCUSwipeViewDirection.Right:
            command = "OSDCursorRight"
        case SCUSwipeViewDirection.Center:
            command = "OSDSelect"
        default:
            break
        }
        
        if let command = command {
            if isHold {
                serviceModel.sendHoldCommand(command)
            } else {
                serviceModel.sendCommand(command)
                sendRelease()
            }
        }
    }
    
    func swipeView(swipeView: SCUSwipeView!, holdInteractionDidEnd interaction: SCUSwipeViewDirection) {
        sendRelease()
    }
    
}
