//
//  HostFoundWifiViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/28/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class HostFoundWifiViewController: FakeNavBarViewController, SAVReachabilityDelegate {
    let iconView = UIImageView(image: UIImage(named: "Wifi")?.tintedImageWithColor(Colors.color1shade1))
    let hostFoundLabel = UILabel(frame: CGRectZero)
    let detailLabel = UILabel(frame: CGRectZero)
    var wifiView = UIView(frame: CGRectZero)
    var wifiLabel = UILabel(frame: CGRectZero)
    let yesButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Yes", comment: "").uppercaseString)
    let noButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("No", comment: "").uppercaseString)
    var noWifiButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Open Settings", comment: "").uppercaseString)
    var bottomButtons = UIView(frame: CGRectZero)
    
    let coordinator:CoordinatorReference<HostOnboardingState>
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        SAVReachability.sharedInstance().addReachabilityObserver(self)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        SAVReachability.sharedInstance().removeReachabilityObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        noButton.color = Colors.color1shade1.colorWithAlphaComponent(0.25)
        
        yesButton.releaseCallback = { [unowned self] in
            self.coordinator.transitionToState(.WifiPassword)
        }
        
        noButton.releaseCallback = { [unowned self] in
            self.coordinator.transitionToState(.SwitchWifi)
        }
        
        noWifiButton.releaseCallback = { [unowned self] in
            self.coordinator.transitionToState(.SwitchWifi)
        }
        
        wifiView = wifiNetworkLabel()

        view.addSubview(iconView)
        view.addSubview(hostFoundLabel)
        view.addSubview(wifiView)
        view.addSubview(detailLabel)
        view.addSubview(noWifiButton)
        
        noWifiButton.hidden = true
        
        hostFoundLabel.text = NSLocalizedString("Is this your home Wi-fi network?", comment: "")
        hostFoundLabel.textColor = Colors.color1shade1
        hostFoundLabel.font = Fonts.subHeadline2
        hostFoundLabel.numberOfLines = 0
        hostFoundLabel.textAlignment = .Center
        
        view.sav_pinView(iconView, withOptions: .CenterX)
        view.sav_pinView(hostFoundLabel, withOptions: .CenterX)
        view.sav_pinView(wifiView, withOptions: .CenterX)
        
        let configuration = SAVViewDistributionConfiguration()
        configuration.interSpace = 0
        configuration.fixedHeight = Sizes.row * 9
        configuration.distributeEvenly = true
        configuration.separatorSize = UIScreen.screenPixel()
        configuration.separatorBlock = {
            return UIView.sav_viewWithColor(Colors.color1shade1.colorWithAlphaComponent(0.25))
        }
        
        bottomButtons = UIView.sav_viewWithEvenlyDistributedViews([noButton, yesButton], withConfiguration: configuration)
        view.addSubview(bottomButtons)
        view.sav_pinView(bottomButtons, withOptions: .Horizontally | .ToBottom)
        
        view.sav_pinView(noWifiButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: noWifiButton, isRelative: false)

        setupConstraints()
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 34)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 60)
        view.sav_pinView(hostFoundLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 9)
        view.sav_pinView(wifiView, withOptions: .ToTop, withSpace: Sizes.row * 67)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 22)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 45)
        view.sav_pinView(hostFoundLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 9)
        view.sav_pinView(wifiView, withOptions: .ToTop, withSpace: Sizes.row * 52)
    }
    
    override func phoneConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 16)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 32)
        view.sav_pinView(hostFoundLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        view.sav_pinView(wifiView, withOptions: .ToTop, withSpace: Sizes.row * 46)
    }
    
    func currentSSIDDidChange(ssid: String!) {
        if let ssid = ssid where count(ssid) > 0 {
            wifiLabel.text = ssid
            bottomButtons.hidden = false
            noWifiButton.hidden = true
        } else {
            wifiLabel.text = NSLocalizedString("No Network Found", comment: "")
            bottomButtons.hidden = true
            noWifiButton.hidden = false
        }
    }
    
    func wifiNetworkLabel() -> UIView {
        let container = UIView(frame: CGRectZero)
        container.backgroundColor = Colors.color1shade3
        
        wifiLabel = UILabel(frame: CGRectZero)
        wifiLabel.textColor = Colors.color1shade1
        wifiLabel.font = Fonts.body
        wifiLabel.lineBreakMode = .ByTruncatingTail
        wifiLabel.textAlignment = .Center

        #if (arch(i386) || arch(x86_64)) && os(iOS)
            wifiLabel.text = NSLocalizedString("SimulatorNetwork", comment: "")
        #else
            wifiLabel.text = SAVReachability.sharedInstance().currentSSID
        #endif
        
        let wifiIcon = UIImageView(image: UIImage(named: "Wifi")?.tintedImageWithColor(Colors.color1shade1))
        
        container.addSubview(wifiLabel)
        container.addSubview(wifiIcon)
        
        container.sav_pinView(wifiIcon, withOptions: .ToLeft, withSpace: Sizes.row)
        container.sav_pinView(wifiIcon, withOptions: .CenterY)
        container.sav_setSize(CGSize(width: 22, height: 22), forView: wifiIcon, isRelative: false)
        
        container.sav_pinView(wifiLabel, withOptions: .ToRight, ofView: wifiIcon, withSpace: Sizes.row)
        container.sav_pinView(wifiLabel, withOptions: .ToRight | .Vertically, withSpace: Sizes.row)
        
        return container
    }
    
    override func handleBack() {
        if coordinator.previousState == .HostFound {
            coordinator.transitionToState(.HostFound)
        } else if coordinator.previousState == .HostsFound {
            coordinator.transitionToState(.HostsFound)
        } else {
            coordinator.transitionToState(.PlugInHost)
        }

    }
}