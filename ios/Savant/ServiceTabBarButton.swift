//
//  ServiceTabBarButtonConfiguration.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ServiceTabBarButtonConfiguration {
    
    let button: SCUButton
    let viewController: UIViewController?
    let restore: Bool
    let initialTab: Bool
    
    init(button b: SCUButton, stylize: Bool = true, viewController vc: UIViewController? = nil, restore r: Bool = true, initialTab it: Bool = false) {
        button = b
        viewController = vc
        restore = r
        initialTab = it
        
        if stylize {
            button.color = Colors.color1shade1
            button.selectedColor = Colors.color4shade1
            button.titleLabel?.font = Fonts.caption1
            
            if let title = button.title {
                button.title = title.uppercaseString
            }
        }
    }
   
}
