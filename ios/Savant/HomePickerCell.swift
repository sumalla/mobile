//
//  HomePickerCell.swift
//  Savant
//
//  Created by Stephen Silber on 4/1/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

enum HomePickerCardType {
    case RemoteMinus
    case RemotePlus
    case LocalMinus
    case LocalPlus
    case RequestAccess
    case Invite
    case InviteWithMessage
    case GuestLocalOnly
    case Onboardable
    case Onboarding
    case HostNotFound
}

class HomePickerCell : CardCell {
    
    var containerView = UIView()
    var mainButton: ProgressButtonView?
    var topLabel: UILabel?
    var messageLabel: UILabel?
    var linkButton: SCUButton?
    
    var type: HomePickerCardType = .Invite

    override func prepareForReuse() {
        super.prepareForReuse()
        
        topLabel = nil
        messageLabel = nil
        mainButton = nil
        linkButton = nil
    }
    
    func layoutCell() {
        
        // Default height of the card is short rather than tall
        switch type {
        case .InviteWithMessage, .GuestLocalOnly, .HostNotFound, .RemoteMinus, .Onboarding:
            setCardHeightForSections(Sizes.row * 34, top: Sizes.row * 20)
        default:
            setCardHeightForSections(Sizes.row * 18, top: Sizes.row * 36)
        }
        
        mainButton?.removeFromSuperview()
        topLabel?.removeFromSuperview()
        messageLabel?.removeFromSuperview()
        linkButton?.removeFromSuperview()
        containerView.removeFromSuperview()
        
        containerView = UIView()
        bottomView.addSubview(containerView)
        bottomView.sav_addFlushConstraintsForView(containerView)
        
        for label in [topLabel, messageLabel] {
            if let label = label {
                label.textColor = Colors.color3shade2
                label.font = Fonts.caption1
                label.textAlignment = .Center
                label.numberOfLines = 0
                label.lineBreakMode = .ByWordWrapping
                containerView.addSubview(label)
            }
        }
        
        if let button = mainButton {
            containerView.addSubview(button)
            containerView.sav_pinView(mainButton, withOptions: .CenterX)
        }
        
        if let link = linkButton {
            containerView.addSubview(link)
        }
        
        switch type {
        case .Invite:
            containerView.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 3)
            containerView.sav_pinView(mainButton, withOptions: .ToTop, withSpace: Sizes.row * 8)
        case .RemoteMinus:
            containerView.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
            containerView.sav_pinView(messageLabel, withOptions: .ToTop, withSpace: Sizes.row * 12)
            containerView.sav_pinView(linkButton, withOptions: .ToBottom, withSpace: Sizes.row * 4)
        case .LocalMinus:
            containerView.sav_pinView(mainButton, withOptions: .ToTop, withSpace: Sizes.row * 4)
            containerView.sav_pinView(linkButton, withOptions: .ToBottom, withSpace: Sizes.row * 4)
        case .RemotePlus, .LocalPlus, .RequestAccess, .Onboardable:
            containerView.sav_pinView(mainButton, withOptions: .ToBottom, withSpace: Sizes.row * 7)
        case .HostNotFound:
            containerView.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
            containerView.sav_pinView(messageLabel, withOptions: .ToTop, withSpace: Sizes.row * 12)
            containerView.sav_pinView(mainButton, withOptions: .ToBottom, withSpace: Sizes.row * 5)
        case .Onboarding:
            containerView.sav_pinView(messageLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
            containerView.sav_pinView(mainButton, withOptions: .ToBottom, withSpace: Sizes.row * 8)
            containerView.sav_pinView(linkButton, withOptions: .ToBottom, withSpace: Sizes.row * 4)
        default:
            break
        }
        
        if let link = linkButton {
            containerView.sav_pinView(linkButton, withOptions: .CenterX)
            link.sizeToFit()
        }
        
        for label in [topLabel, messageLabel] {
            if let label = label {
                containerView.sav_pinView(label, withOptions: .CenterX)
                containerView.sav_pinView(label, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 3)
            }
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func linkButtonWithText(text: String) -> SCUButton {
        return SCUButton(style: .UnderlinedText, title: text)
    }
    
    func pillButtonWithText(text: String) -> ProgressButtonView {
        return ProgressButtonView(frame: CGRectZero, buttonTitle: text, radius: Sizes.row * 2.5, lineWidth: 3, tintColor: Colors.color5shade2)
    }
    
    func attributedLabelWithString(text: String) -> UILabel {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Sizes.row
        
        var labelText = NSMutableAttributedString(string: text)
        labelText.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, labelText.length))
        
        let label = UILabel()
        label.attributedText = labelText
        
        return label
    }

    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        let item = modelItem as! HomePickerModelItem
        homeLabel.text = item.title

        type = item.cardType
        
        switch type {
        case .RemotePlus:
            mainButton = pillButtonWithText(NSLocalizedString("Connect", comment: ""))
        case .RemoteMinus:
            topLabel = attributedLabelWithString(NSLocalizedString("Connection Unavailable", comment: ""))
            messageLabel = attributedLabelWithString(String(format: NSLocalizedString("WiFi network at %@ not found. Subscribe to Savant Plus to access your home remotely", comment: ""), item.title!))
            linkButton = linkButtonWithText(NSLocalizedString("Learn About Savant Plus", comment: ""))
        case .LocalPlus:
            mainButton = pillButtonWithText(NSLocalizedString("Connect", comment: ""))
        case .LocalMinus:
            mainButton = pillButtonWithText(NSLocalizedString("Connect", comment: ""))
            linkButton = linkButtonWithText(NSLocalizedString("Learn About Remote Access", comment: ""))
        case .Invite:
            topLabel = attributedLabelWithString(String(format: NSLocalizedString("%@ has sent you an invite.", comment: ""), "Jerry"))
            mainButton = pillButtonWithText(NSLocalizedString("Accept", comment: ""))
        case .RequestAccess:
            mainButton = pillButtonWithText(NSLocalizedString("Request Access", comment: ""))
        case .HostNotFound:
            topLabel = attributedLabelWithString(NSLocalizedString("Connection Unavailable", comment: ""))
            messageLabel = attributedLabelWithString(NSLocalizedString("We were unable to connect to your host. Make sure your wireless router is working properly.", comment: ""))
            mainButton = pillButtonWithText(NSLocalizedString("Retry Connection", comment: ""))
        case .Onboardable:
            mainButton = pillButtonWithText(NSLocalizedString("Connect", comment: ""))
        case .Onboarding:
            messageLabel = attributedLabelWithString(NSLocalizedString("Now that you have a Savant Plus account, we need to link it to your home. Just tap Continue to get started.", comment: ""))
            mainButton = pillButtonWithText(Strings.continu)
            linkButton = linkButtonWithText(NSLocalizedString("No, Skip This Step", comment: ""))
            linkButton?.color = Colors.color4shade1
        default:
            break
        }
        
        layoutCell()

        if let button = mainButton {
            if item.animating {
                mainButton?.setProgressState(.Spinning)
            } else {
                mainButton?.setProgressState(.Normal)
            }
        }

    }
}