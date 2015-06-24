//
//  LightingDeviceFoundCard.swift
//  Savant
//
//  Created by Stephen Silber on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class LightingDeviceFoundCard: DeviceFoundCard {
    
    var lightingTypeButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Switch", comment: ""))

    internal var lampModuleType:ConfigurableDeviceLampModuleType? {
        didSet {
            if lampModuleType == ConfigurableDeviceLampModuleType.Switch {
                lightingTypeButton.title = NSLocalizedString("Switch", comment: "")
            } else {
                lightingTypeButton.title = NSLocalizedString("Dimmer", comment: "")
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTriangleToButton(lightingTypeButton)
    }
    
    override func setupConstraints() {
        contentView.sav_pinView(blinkingLabel, withOptions: .ToTop, withSpace: Sizes.row * 28)
        
        containerView.addSubview(lightingTypeButton)
        containerView.sav_pinView(lightingTypeButton, withOptions: .CenterX)

        containerView.sav_pinView(lightingTypeButton, withOptions: .ToTop, withSpace: Sizes.row * 4)
        containerView.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5), forView: lightingTypeButton, isRelative: false)

        containerView.sav_pinView(mainButton, withOptions: .ToTop, withSpace: Sizes.row * 11)
        containerView.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5), forView: mainButton, isRelative: false)

        containerView.sav_pinView(linkButton, withOptions: .ToTop, withSpace: Sizes.row * 19)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCardHeight() {
        setCardHeightForSections(Sizes.row * 24, top: Sizes.row * 30)
    }
}
