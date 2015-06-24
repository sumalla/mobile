//
//  HostFoundViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/22/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import Coordinator

class HostFoundViewController: FakeNavBarViewController, SAVReachabilityDelegate {
    let iconView = UIImageView(image: UIImage(named: "SmartHost")?.tintedImageWithColor(Colors.color1shade1))
    let hostFoundLabel = UILabel(frame: CGRectZero)
    let detailLabel = UILabel(frame: CGRectZero)
    var wifiView = UIView(frame: CGRectZero)
    var wifiLabel = UILabel(frame: CGRectZero)
    let bottomButton = SCUButton(style: .PinnedButton, title: NSLocalizedString("Next", comment: "").uppercaseString)
    let coordinator:CoordinatorReference<HostOnboardingState>
    var hostUID: String?
    var showingUID = false
    
    init(coordinator:CoordinatorReference<HostOnboardingState>, uid: String?) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        SAVReachability.sharedInstance().addReachabilityObserver(self)
        hostUID = uid
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        SAVReachability.sharedInstance().removeReachabilityObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(iconView)
        view.addSubview(hostFoundLabel)
        view.addSubview(detailLabel)
        view.addSubview(bottomButton)
        
        bottomButton.releaseCallback =  { [weak self] in
            self?.coordinator.transitionToState(.HostFoundWifi(nil))
        }
        
        hostFoundLabel.text = NSLocalizedString("Host Found", comment: "")
        hostFoundLabel.textColor = Colors.color1shade1
        hostFoundLabel.font = Fonts.subHeadline2
        hostFoundLabel.textAlignment = .Center
        
        let tripleTap = UITapGestureRecognizer()
        tripleTap.numberOfTapsRequired = 3
        tripleTap.sav_handler = { [unowned self] (state, point) in
            if let uid = self.hostUID {
                self.showingUID = !self.showingUID
                self.hostFoundLabel.text = self.showingUID ? uid : NSLocalizedString("Host Found", comment: "")
                self.hostFoundLabel.font = self.showingUID ? Fonts.body : Fonts.subHeadline2
            }
        }
        
        view.addGestureRecognizer(tripleTap)
        
        detailLabel.text = NSLocalizedString("Now lets connect it to your Wi-Fi.", comment: "")
        detailLabel.textColor = Colors.color1shade1
        detailLabel.font = Fonts.body
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .Center
        
        view.sav_pinView(iconView, withOptions: .CenterX)
        view.sav_pinView(hostFoundLabel, withOptions: .CenterX)
        view.sav_pinView(detailLabel, withOptions: .CenterX)

        view.sav_pinView(bottomButton, withOptions: .Horizontally | .ToBottom)
        view.sav_setHeight(Sizes.row * 9, forView: bottomButton, isRelative: false)

        setupConstraints()
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 34)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 60)
        
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 67)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 9)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 22)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 45)
        
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 52)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 9)
    }
    
    override func phoneConstraints() {
        
        view.sav_pinView(iconView, withOptions: .ToTop, withSpace: Sizes.row * 16)
        view.sav_pinView(hostFoundLabel, withOptions: .ToTop, withSpace: Sizes.row * 32)
        
        view.sav_pinView(detailLabel, withOptions: .ToTop, withSpace: Sizes.row * 38)
        view.sav_pinView(detailLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 9)
    }
    
    override func handleBack() {
        coordinator.transitionToState(.Start)
    }
}
