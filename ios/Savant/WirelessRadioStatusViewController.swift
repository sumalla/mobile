//
//  WirelessRadioStatusViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class WirelessRadioStatusViewController: FakeNavBarViewController, SAVReachabilityDelegate {
    var iconsView: UIView = UIView(frame: CGRectZero)
    let topLabel = UILabel(frame: CGRectZero)
    let detailLabel = UILabel(frame: CGRectZero)
    let arrow = UIImageView(image: UIImage(named: "chevron-up")?.tintedImageWithColor(Colors.color1shade1))
    
    let hostCoordinator:CoordinatorReference<HostOnboardingState>?
    let deviceCoordinator:CoordinatorReference<DeviceOnboardingState>?
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.hostCoordinator = coordinator
        self.deviceCoordinator = nil
        super.init(nibName: nil, bundle: nil)
        SAVReachability.sharedInstance().addReachabilityObserver(self)
    }
    
    init(coordinator:CoordinatorReference<DeviceOnboardingState>) {
        self.deviceCoordinator = coordinator
        self.hostCoordinator = nil
        super.init(nibName: nil, bundle: nil)
        SAVReachability.sharedInstance().addReachabilityObserver(self)
    }
    
    deinit {
        SAVReachability.sharedInstance().removeReachabilityObserver(self)
    }
    

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        topLabel.textColor = Colors.color1shade1
        topLabel.font = Fonts.subHeadline3
        topLabel.textAlignment = .Center
        topLabel.numberOfLines =  0
        topLabel.text = currentAvailabilityString()
        
        detailLabel.textColor = Colors.color1shade1
        detailLabel.font = Fonts.caption1
        detailLabel.textAlignment = .Center
        detailLabel.numberOfLines = 0
        detailLabel.text = NSLocalizedString("Swipe up from the bottom of the screen to open controls", comment: "")
        
        view.addSubview(topLabel)
        view.addSubview(detailLabel)
        view.addSubview(arrow)
        
        view.sav_pinView(topLabel, withOptions: .CenterX)
        view.sav_pinView(topLabel, withOptions: .CenterY)
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
        
        view.sav_pinView(detailLabel, withOptions: .CenterX)
        view.sav_pinView(detailLabel, withOptions: .CenterY, withSpace: Sizes.row * 8)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.row * 4)
        
        view.sav_pinView(arrow, withOptions: .CenterX)
        view.sav_pinView(arrow, withOptions: .ToBottom, withSpace: Sizes.row * 3)

        setArrowAnimated(true)
        updateRadioIconView()
    }
    
    func wifiStatusDidChange(enabled: Bool) {
        topLabel.text = currentAvailabilityString()
        updateRadioIconView()
    }
    
    func bluetoothStatusDidChange(enabled: Bool) {
        topLabel.text = currentAvailabilityString()
        updateRadioIconView()
    }

    func currentAvailabilityString() -> String {
        var contentString = ""
        
        if !SAVReachability.sharedInstance().bluetoothEnabled && !SAVReachability.sharedInstance().wifiEnabled {
            contentString = "Bluetooth and WiFi"
        } else if !SAVReachability.sharedInstance().bluetoothEnabled {
            contentString = "Bluetooth"
        } else if !SAVReachability.sharedInstance().wifiEnabled {
            contentString = "WiFi"
        }
        
        return "Turn on \(contentString) to proceed"
    }

    func setArrowAnimated(animated: Bool) {
        if animated {
            UIView.animateWithDuration(1, delay: 0, options: .Autoreverse | .Repeat, animations: { () -> Void in
                self.arrow.frame.origin.y -= Sizes.row * 2
            }, completion: nil)
        } else {
            arrow.layer.removeAllAnimations()
        }
    }

    func updateRadioIconView() {
        iconsView.removeFromSuperview()
        
        var iconViews = [UIImageView]()
        if !SAVReachability.sharedInstance().bluetoothEnabled {
            let bluetoothIcon = UIImageView(image: UIImage(named: "Bluetooth")?.tintedImageWithColor(Colors.color1shade1))
            iconViews.append(bluetoothIcon)
        }
        
        if !SAVReachability.sharedInstance().wifiEnabled {
            let wifiIcon = UIImageView(image: UIImage(named: "Wifi")?.tintedImageWithColor(Colors.color1shade1))
            iconViews.append(wifiIcon)
        }
        
        var container = UIView(frame: CGRectZero)

        if iconViews.count > 0 {
            
            let configuration = SAVViewDistributionConfiguration()
            configuration.interSpace = Sizes.row * 3
            configuration.fixedHeight = 60.0
            configuration.fixedWidth = 60.0
            
            container = UIView.sav_viewWithEvenlyDistributedViews(iconViews, withConfiguration: configuration)
        }
        
        iconsView = container
        view.addSubview(iconsView)
        view.sav_pinView(iconsView, withOptions: .CenterX)
        view.sav_pinView(iconsView, withOptions: .ToTop, ofView:topLabel, withSpace: Sizes.row * 6)
    }
    
    override func handleBack() {
        if let hc = hostCoordinator {
            hc.transitionToState(.Start)
        }
        if let dc = deviceCoordinator {
            dc.transitionToState(.ConnectDevices)
        }
    }
}
