//
//  HomeNamingViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/28/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class HomeNamingViewController: FakeNavBarViewController {
    
    let cardView = UIView(frame: CGRectZero)
    let cameraButton = SCUButton(style: .Custom, image: UIImage(named: "edit")?.tintedImageWithColor(Colors.color1shade1).scaleToSize(CGSize(width: 22, height: 22)))
    let homeNameField = ErrorTextField(style: .Light)
    let descriptionLabel = UILabel(frame: CGRectZero)
    let bottomButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Next", comment: "").uppercaseString)
   
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
        
        cardView.backgroundColor = Colors.color5shade1.colorWithAlphaComponent(0.25)
        cardView.layer.cornerRadius = 3
        
        homeNameField.placeholder = NSLocalizedString("home name", comment: "")
        homeNameField.textField.textAlignment = .Center
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 12
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: NSLocalizedString("Add a personal touch by naming your home. You can add a custom image now or do it later in Settings.", comment: ""))
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        
        descriptionLabel.attributedText = attrString
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = Colors.color1shade1
        descriptionLabel.font = Fonts.caption1
        
        view.addSubview(cardView)
        view.addSubview(bottomButton)

        cardView.addSubview(cameraButton)
        cardView.addSubview(homeNameField)
        cardView.addSubview(descriptionLabel)
        
        view.sav_setHeight(Sizes.row * 50, forView: cardView, isRelative: false)
        view.sav_pinView(cardView, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        view.sav_pinView(cardView, withOptions: .ToTop, withSpace: Sizes.row * 18)
        
        cardView.sav_pinView(cameraButton, withOptions: .ToTop | .ToRight, withSpace: Sizes.row * 3)
        cardView.sav_pinView(homeNameField, withOptions: .CenterX)
        cardView.sav_pinView(homeNameField, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        cardView.sav_pinView(homeNameField, withOptions: .ToTop, withSpace: Sizes.row * 14)
        
        cardView.sav_pinView(descriptionLabel, withOptions: .CenterX)
        cardView.sav_pinView(descriptionLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 3)
        cardView.sav_pinView(descriptionLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        
        view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)
    }
    
    override func handleBack() {
        coordinator.transitionToState(.WifiPassword)
    }
}
