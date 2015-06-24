//
//  ServiceViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ServiceViewController: UIViewController {
    
    let serviceModel: ServiceModel
    var dismissalHandler: (() -> ())?
    let contentView = UIView()
    let volumeTabBarButton = ServiceTabBarButtonConfiguration(button: SCUButton(image: UIImage(named: "increaseVolume")))
    let mask = UIView.sav_viewWithColor(Colors.color5shade3)
    
    var panGesture: UIPanGestureRecognizer? {
        didSet {
            if let oldPan = oldValue {
                navigationController?.navigationBar.removeGestureRecognizer(oldPan)
                
                if let oldView = oldPan.view {
                    oldView.removeGestureRecognizer(oldPan)
                }
            }
            
            if let newPan = panGesture {
                navigationController?.navigationBar.addGestureRecognizer(newPan)
            }
        }
    }
    
    private var _tabBarButtons: [ServiceTabBarButtonConfiguration]?
    private var statusBarInitiallyHidden = false
    private var currentViewController: UIViewController?
    
    init(service: SAVService, global: Bool) {
        serviceModel = ServiceModel(service: service, global: global)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        volumeTabBarButton.button.target = self
        volumeTabBarButton.button.releaseAction = "presentVolume"
        
        /* Assigning directly to this var was causing a bad access. wat. */
        let dumbSwiftHack = UIApplication.sharedApplication().statusBarHidden
        statusBarInitiallyHidden = dumbSwiftHack
        
        view.backgroundColor = Colors.color2shade1
        edgesForExtendedLayout = UIRectEdge.None
        
        let dismiss = SCUButton(style: .Light, image: UIImage(named: "chevron-down"))
        dismiss.frame = CGRect(x: 0, y: 0, width: 70, height: 44)
        dismiss.target = self
        dismiss.releaseAction = "dismiss"
        dismiss.buttonInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismiss)
        
        if serviceModel.canPowerOff {
            let power = SCUButton(style: .Accent, image: UIImage(named: "Power"))
            power.frame = CGRect(x: 0, y: 0, width: 70, height: 44)
            power.target = self
            power.releaseAction = "powerOff"
            power.buttonInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: power)
        }
        
        let topLine = UIView.sav_viewWithColor(Colors.color1shade5)
        view.addSubview(topLine)
        view.sav_pinView(topLine, withOptions: .ToTop | .Horizontally)
        view.sav_setHeight(Sizes.pixel * 2, forView: topLine, isRelative: false)
        
        let bottomLine = UIView.sav_viewWithColor(Colors.color1shade5)
        view.addSubview(bottomLine)
        view.sav_setHeight(Sizes.pixel * 2, forView: bottomLine, isRelative: false)
        view.sav_pinView(bottomLine, withOptions: .Horizontally)
        
        view.addSubview(contentView)
        view.sav_pinView(contentView, withOptions: .Horizontally)
        view.sav_pinView(contentView, withOptions: .ToBottom, ofView: topLine, withSpace: 0)
        
        _tabBarButtons = tabBarButtons()
        
        if let tabBarButtons = _tabBarButtons {
            parseTabBarButtons(tabBarButtons)
            let distConfig = SAVViewDistributionConfiguration()
            distConfig.distributeEvenly = true
            distConfig.interSpace = 0
            let buttons = map(tabBarButtons) {
                return $0.button
            }
            
            let tabBar = UIView.sav_viewWithEvenlyDistributedViews(buttons, withConfiguration: distConfig)
            tabBar.backgroundColor = Colors.color2shade1
            view.addSubview(tabBar)
            view.sav_pinView(tabBar, withOptions: .ToBottom | .Horizontally)
            view.sav_setHeight(Sizes.row * 9, forView: tabBar, isRelative: false)
            view.sav_pinView(bottomLine, withOptions: .ToTop, ofView: tabBar, withSpace: 0)
        } else {
            view.sav_pinView(bottomLine, withOptions: .ToBottom)
        }
        
        view.sav_pinView(contentView, withOptions: .ToTop, ofView: bottomLine, withSpace: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        serviceModel.powerOnIfNecessary()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !statusBarInitiallyHidden {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        }
    }
    
    func dismiss() {
        if let dismissalHandler = dismissalHandler {
            dismissalHandler()
        }
    }
    
    func powerOff() {
        serviceModel.powerOff()
        dismiss()
    }
    
    func tabBarButtons() -> [ServiceTabBarButtonConfiguration]? {
        return nil
    }
    
    private func parseTabBarButtons(buttons: [ServiceTabBarButtonConfiguration]) {
        var foundInitialTab = false
        
        for button in buttons {
            if let vc = button.viewController {
                button.button.releaseCallback = { [unowned self, unowned vc] in
                    if let cvc = self.currentViewController {
                        if cvc === vc {
                            /* don't do any switching logic if we've tried switching to the already selected tab */
                            return
                        }
                        
                        cvc.sav_removeFromParentViewController()
                    }
                    
                    self.addChildViewController(vc)
                    self.contentView.addSubview(vc.view)
                    self.contentView.sav_addFlushConstraintsForView(vc.view)
                    self.currentViewController = vc
                    
                    /* Unselect all the other buttons and select the current button */
                    for b in buttons {
                        b.button.selected = false
                    }
                    
                    button.button.selected = true
                }
            }
            
            if button.initialTab {
                if foundInitialTab {
                    fatalError("Hey, you probably shouldn't make two tabs the initialTab. SHAME!")
                } else {
                    foundInitialTab = true
                    
                    button.button.releaseCallback()
                }
            }
        }
    }
    
    func presentVolume() {
        var roomContext: String?
        
        if !serviceModel.global {
            roomContext = serviceModel.service?.zoneName
        }
        
        if mask.superview == nil {
            mask.alpha = 1
            if let v = parentViewController?.view {
                v.addSubview(mask)
                v.sav_addFlushConstraintsForView(mask)
            }
        }
        
        let vc = VolumeViewController(volumeModel: VolumeModel(serviceModel: serviceModel, roomContext: roomContext))
        vc.dismissalBlock = { [unowned self] in
            if self.mask.superview != nil {
                UIView.animateWithDuration(0.2, animations: {
                    self.mask.alpha = 0
                }, completion: { (complete) in
                    if complete {
                        self.mask.removeFromSuperview()
                    }
                })
            }
        }
        
        presentViewController(vc, animated: true, completion: nil)
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.isPhone() {
            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
}
