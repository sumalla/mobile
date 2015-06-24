//
//  NoWifiPasswordViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/30/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class NoWifiPasswordViewController: FakeNavBarViewController {
    let card = UIView(frame: CGRectZero)
    let topLabel = UILabel(frame: CGRectZero)
    let detailLabel = UILabel(frame: CGRectZero)
    let bottomButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Connect", comment: "").uppercaseString)
    
    let coordinator:CoordinatorReference<HostOnboardingState>
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomButton.releaseCallback =  { [unowned self] in
            self.coordinator.transitionToState(.CheckWifiCredentials(""))
        }
        
        card.backgroundColor = Colors.color1shade1
        card.layer.cornerRadius = 3
        
        topLabel.numberOfLines = 0
        topLabel.font = Fonts.subHeadline2
        topLabel.textColor = Colors.color1shade1
        topLabel.textAlignment = .Center
        topLabel.text = NSLocalizedString("Continue Without a Wi-Fi Password?", comment: "")
        
        detailLabel.numberOfLines = 0
        detailLabel.font = Fonts.caption1
        detailLabel.textColor = Colors.color3shade2
        detailLabel.lineBreakMode = .ByWordWrapping
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 12
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: NSLocalizedString("Savant recommends setting up your system with a password protected Wi-Fi network to ensure the security of your home.", comment: ""))
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        
        detailLabel.attributedText = attrString
        
        view.addSubview(card)
        view.addSubview(bottomButton)
        view.addSubview(topLabel)
        
        view.sav_pinView(topLabel, withOptions: .CenterX)
        view.sav_pinView(card, withOptions: .CenterX)
        
        view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
        
        card.addSubview(detailLabel)
        
        setupConstraints()
    }
    
    override func phoneConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 34)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 40, height: Sizes.row * 18), forView: card, isRelative: false)
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 23)
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
        
        card.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 3)
        card.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 3)
    }
    
    override func universalPadConstraints() {
        view.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        
//        card.sav_pinView(detailLabel, withOptions: .CenterX)
        card.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)
        card.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 16)
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(card, withOptions: .CenterY)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 28), forView: card, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(card, withOptions: .CenterY)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 28), forView: card, isRelative: false)
    }
    
    override func handleBack() {
        coordinator.transitionToState(.WifiPassword)
    }
}
