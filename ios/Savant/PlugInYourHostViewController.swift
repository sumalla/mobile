//
//  PlugInYourHostViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/28/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class PlugInYourHostViewController: OnboardingViewController {
    let card = UIView(frame: CGRectZero)
    let topLabel = UILabel(frame: CGRectZero)
    let graphicImageView = UIImageView(image: UIImage(named: ""))
    let bottomLabel = UILabel(frame: CGRectZero)
    let bottomButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Next", comment: "").uppercaseString)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomButton.releaseCallback =  { [weak self] in
            self?.coordinator.transitionToState(.Searching)
        }
        
        card.backgroundColor = Colors.color1shade1
        card.layer.cornerRadius = 3
        
        topLabel.numberOfLines = 0
        topLabel.font = Fonts.body
        topLabel.textColor = Colors.color3shade2
        topLabel.textAlignment = .Center
        topLabel.text = NSLocalizedString("Plug In Your Savant Host", comment: "")
        
        bottomLabel.numberOfLines = 0
        bottomLabel.font = Fonts.caption1
        bottomLabel.textColor = Colors.color3shade2
        bottomLabel.lineBreakMode = .ByWordWrapping
        bottomLabel.textAlignment = .Center

        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: NSLocalizedString("For the best results, place it in a central location with a strong Wi-Fi signal.", comment: ""))
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))

        bottomLabel.attributedText = attrString
        
        view.addSubview(card)
        
        card.addSubview(topLabel)
        card.addSubview(graphicImageView)
        card.addSubview(bottomLabel)
        view.addSubview(bottomButton)

        view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
        card.sav_pinView(topLabel, withOptions: .CenterX)
        card.sav_pinView(graphicImageView, withOptions: .CenterX)
        card.sav_pinView(bottomLabel, withOptions: .CenterX)
        card.sav_setWidth(0.8, forView: bottomLabel, isRelative: true)
        
        view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
        
        setupConstraints()
    }

    override func padPortraitConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 30)
        view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 32)
        view.sav_pinView(card, withOptions: .CenterX)
        view.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, forView: card, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 13)
        view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 17)
        view.sav_pinView(card, withOptions: .CenterX)
        view.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, forView: card, isRelative: false)
    }
    
    override func universalPadConstraints() {
        card.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
        card.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 8)
        card.sav_pinView(graphicImageView, withOptions: .ToTop, withSpace: Sizes.row * 14)
        card.sav_pinView(bottomLabel, withOptions: .ToTop, withSpace: Sizes.row * 57)
    }
    
    override func phoneConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 13)
        view.sav_pinView(card, withOptions: .ToBottom, withSpace: Sizes.row * 16)
        view.sav_pinView(card, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        
        card.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
        card.sav_pinView(topLabel, withOptions: .CenterX)
        card.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)

        card.sav_pinView(graphicImageView, withOptions: .ToTop, withSpace: Sizes.row * 14)
        card.sav_pinView(bottomLabel, withOptions: .ToTop, withSpace: Sizes.row * 42)
        
    }
    
    override func handleBack() {
        coordinator.transitionToState(.Start)
    }
}
