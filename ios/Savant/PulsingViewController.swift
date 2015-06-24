//
//  PulsingViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/22/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

enum PulseState: Equatable {
    case None
    case Searching
    case SearchingSavantDevices
    case SearchingMoreSavantDevices
    case Connecting
    case Success
	case DevicesAdded
    case AdditionalDevicesFound
}

class PulsingViewController: FakeNavBarViewController {
    let iconView = PulsingIconView(frame: CGRectZero)
    let label = UILabel(frame: CGRectZero)
    let subtitleLabel = UILabel(frame: CGRectZero)
    var buttonView = UIView(frame: CGRectZero)
    var pulseState: PulseState = .None
    let checkImageView = UIImageView(image: UIImage(named: "SuccessCheck")?.tintedImageWithColor(Colors.color1shade1))
    
    let deviceCoordinator:CoordinatorReference<DeviceOnboardingState>?
    let hostCoordinator:CoordinatorReference<HostOnboardingState>?
	
	var numberOfDevices:Int = 0
	
    init(coordinator:CoordinatorReference<HostOnboardingState>, state: PulseState) {
        self.hostCoordinator = coordinator
        self.deviceCoordinator = nil
        self.pulseState = state
        super.init(nibName: nil, bundle: nil)
    }

	init(coordinator:CoordinatorReference<DeviceOnboardingState>, state: PulseState, numberOfDevices:Int = 0) {
        self.deviceCoordinator = coordinator
        self.hostCoordinator = nil
		self.numberOfDevices = numberOfDevices
        self.pulseState = state
        super.init(nibName: nil, bundle: nil)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.textColor = Colors.color1shade1
        label.font = Fonts.subHeadline2
        label.textAlignment = .Center
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        
        subtitleLabel.textColor = Colors.color1shade1
        subtitleLabel.font = Fonts.body
        subtitleLabel.textAlignment = .Center
        subtitleLabel.lineBreakMode = .ByWordWrapping
        subtitleLabel.numberOfLines = 0

        iconView.layer.cornerRadius = CGRectGetHeight(iconView.frame)
        
        view.addSubview(iconView)
        view.addSubview(label)
        view.addSubview(subtitleLabel)
        
        iconView.addSubview(checkImageView)
        iconView.sav_addCenteredConstraintsForView(checkImageView)
        checkImageView.hidden = true
        
        view.sav_pinView(iconView, withOptions: .CenterX)
        view.sav_pinView(label, withOptions: .CenterX)
        view.sav_pinView(subtitleLabel, withOptions: .CenterX)

        setState(pulseState)

        setupConstraints()
    }
    
    override func phoneConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 16)
        
        view.sav_pinView(label, withOptions: .ToTop, withSpace: Sizes.row * 32)
        view.sav_pinView(label, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        
        view.sav_pinView(subtitleLabel, withOptions: .ToTop, withSpace: Sizes.row * 48)
        view.sav_pinView(subtitleLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 34)
        
        view.sav_pinView(label, withOptions: .ToTop, withSpace: Sizes.row * 60)
        view.sav_pinView(label, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 10)
        
        view.sav_pinView(subtitleLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 18)
        view.sav_pinView(subtitleLabel, withOptions: .ToTop, withSpace: Sizes.row * 68)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 22)
        
        view.sav_pinView(label, withOptions: .ToTop, withSpace: Sizes.row * 45)
        view.sav_pinView(label, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 10)
        
        view.sav_pinView(subtitleLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 18)
        view.sav_pinView(subtitleLabel, withOptions: .ToTop, withSpace: Sizes.row * 53)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setState(state: PulseState) {
        pulseState = state
        
        switch state {
        case .Searching:
            label.text = NSLocalizedString("Searching...", comment: "")
            subtitleLabel.text = ""
            iconView.imageView.image = UIImage(named: "SmartHost")?.tintedImageWithColor(Colors.color1shade1)
            checkImageView.hidden = true
            iconView.startAnimating()
        case .SearchingSavantDevices:
            label.text = Strings.searchingForDevices
            subtitleLabel.text = Strings.searchingForDevicesSubtitle
            iconView.imageView.image = UIImage(named: "Plus")?.tintedImageWithColor(Colors.color1shade1)
            checkImageView.hidden = true
            iconView.startAnimating()
        case .SearchingMoreSavantDevices:
            label.text = Strings.searchingForMoreDevices
            subtitleLabel.text = Strings.searchingForMoreDevicesSubtitle
            iconView.imageView.image = UIImage(named: "Plus")?.tintedImageWithColor(Colors.color1shade1)
            checkImageView.hidden = true
            iconView.startAnimating()
        case .Connecting:
            label.text = NSLocalizedString("Connecting...", comment: "")
            subtitleLabel.text = ""
            iconView.imageView.image = UIImage(named: "SmartHost")?.tintedImageWithColor(Colors.color1shade1)
            checkImageView.hidden = true
            iconView.startAnimating()
        case .Success:
            label.text = NSLocalizedString("Success", comment: "")
            subtitleLabel.text = ""
            iconView.imageView.image = UIImage(named: "SuccessCircle")?.tintedImageWithColor(UIColor.sav_colorWithRGBValue(0x5fe785))
            checkImageView.hidden = false
            iconView.stopAnimating()
        case .DevicesAdded:
			if numberOfDevices > 0 {
            label.text = Strings.devicesAdded(numberOfDevices)
            subtitleLabel.text = Strings.devicesFoundSubtitle
            iconView.imageView.image = UIImage(named: "SuccessCircle")?.tintedImageWithColor(UIColor.sav_colorWithRGBValue(0x5fe785))
            checkImageView.hidden = false
            iconView.stopAnimating()
            NSTimer.sav_scheduledBlockWithDelay(2, block: { [unowned self] () -> Void in
                self.deviceCoordinator!.transitionToState(.Searching)
            })
			} else {
				fatalError("Set numberOfDevices to higher then 0 use this state.")
			}
        case .AdditionalDevicesFound:
            label.text = Strings.additionalDevicesFound(1)
            subtitleLabel.text = Strings.additionalDevicesFoundSubtitle
            iconView.imageView.image = UIImage(named: "Wifi")?.tintedImageWithColor(Colors.color1shade1)
            checkImageView.hidden = true
            iconView.stopAnimating()
        default:
            break
        }
        
        setupBottomButtons(state)
    }
    
    func setupBottomButtons(state: PulseState) {
        if let buttons = bottomButtonsForState(state) {
            buttonView.removeFromSuperview()
            let configuration = SAVViewDistributionConfiguration()
            configuration.interSpace = 0
            configuration.fixedHeight = Sizes.row * 9
            configuration.distributeEvenly = true
            configuration.separatorSize = UIScreen.screenPixel()
            configuration.separatorBlock = {
                return UIView.sav_viewWithColor(Colors.color1shade1.colorWithAlphaComponent(0.25))
            }
            
            buttonView = UIView.sav_viewWithEvenlyDistributedViews(buttons, withConfiguration: configuration)
            view.addSubview(buttonView)
            view.sav_pinView(buttonView, withOptions: .Horizontally | .ToBottom)
        }
    }
    
    func bottomButtonsForState(state: PulseState) -> [SCUButton]? {
        var buttons = [SCUButton]()
        
        switch state {
        case .DevicesAdded:
            let noButton = SCUButton(style: .PinnedButton, title: Strings.no)
            let yesButton = SCUButton(style: .PinnedButton, title: Strings.yes)
            noButton.releaseCallback = {
                self.deviceCoordinator?.transitionToState(.Searching)
            }
            yesButton.releaseCallback = {
                RootCoordinator.transitionToState(.Interface)
            }
            
            buttons.append(noButton)
            buttons.append(yesButton)
            
        case .AdditionalDevicesFound:
            let nextButton = SCUButton(style: .PinnedButton, title: Strings.no)

            nextButton.releaseCallback = {
                self.deviceCoordinator?.transitionToState(.Searching)
            }
            
            buttons.append(nextButton)
        default:
            return nil
        }
        
        return buttons
    }
    
    func startAnimation() {
        
    }
    
    override func handleBack() {
        if let coordinator = hostCoordinator {
            coordinator.transitionToState(.Start)
        } else if let coordinator = deviceCoordinator {
            coordinator.transitionToState(.ConnectDevices)
        }
    }
}
