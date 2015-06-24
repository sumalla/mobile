//
//  CameraLiveViewController.swift
//  Prototype
//
//  Created by Joseph Ross on 3/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import SDK

class HomeMonitorLiveViewController: UIViewController, SCUActionSheetDelegate, UIScrollViewDelegate, SAVVideoViewDelegate, SignalingClientDelegate, SystemStatusDelegate {
    
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))
    
    var zoomer:UIScrollView! = nil
    var videoView:SAVVideoView! = nil
    
    var cameraClient:CameraRestClient? = nil
    var signalingClient:SignalingClient? = nil
    var navBar:SCUGradientView! = nil
    var bottomBar:SCUGradientView! = nil
    var blurView:UIVisualEffectView! = nil
    var senseLabel:UILabel! = nil
    var protectButton:SCUButton! = nil
    var actionsButton:SCUButton! = nil
    var livePill:UILabel! = nil
    var tapRecognizer:UITapGestureRecognizer! = nil
    var doubleTapRecognizer:UITapGestureRecognizer! = nil
    
    var actionSheet:SCUActionSheet? = nil
    var homeMonitor:HomeMonitor! = nil
    var hudTimer:NSTimer? = nil
    let kHUDTimeout = 5.0 //seconds
    var isBorrowingLiveStream = false
    
    
    init(homeMonitor:HomeMonitor) {
        self.homeMonitor = homeMonitor
        super.init(nibName: nil, bundle: nil)
    }
    
    init(homeMonitor:HomeMonitor, cameraClient:CameraRestClient?, signalingClient:SignalingClient?) {
        self.isBorrowingLiveStream = true
        self.homeMonitor = homeMonitor
        self.cameraClient = cameraClient
        self.signalingClient = signalingClient
        super.init(nibName: nil, bundle: nil)
        signalingClient?.delegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.color5shade1
        
        zoomer = UIScrollView()
        view.addSubview(zoomer)
        zoomer.delegate = self
        zoomer.bouncesZoom = true
        zoomer.maximumZoomScale = 5.0
        zoomer.minimumZoomScale = 1.0
        
        videoView = SAVVideoView()
        videoView.delegate = self
        zoomer.addSubview(videoView)
        videoView.setPreviewImage(homeMonitor.snapshot)
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        view.addSubview(blurView)
        let inSenseMode = homeMonitor.mode == .Sense
        blurView.alpha = inSenseMode ? 1.0 : 0.0
        senseLabel = UILabel()
        senseLabel.alpha = inSenseMode ? 1.0 : 0.0
        senseLabel.text = "Camera will not record\nwhile in Sense mode."
        senseLabel.textColor = Colors.color1shade1
        senseLabel.numberOfLines = 2
        senseLabel.font = Fonts.body
        senseLabel.textAlignment = .Center
        view.addSubview(senseLabel)
        view.sav_addCenteredConstraintsForView(senseLabel)
        
        setupNavBar()
        setupBottomBar()
        setupLivePill()
        tapRecognizer = UITapGestureRecognizer(target: self, action:"videoTap:")
        tapRecognizer.numberOfTapsRequired = 1
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "videoDoubleTap:")
        doubleTapRecognizer.numberOfTapsRequired = 2
        tapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        videoView?.addGestureRecognizer(tapRecognizer)
        videoView?.visibleVideoView().addGestureRecognizer(doubleTapRecognizer)
        
        if cameraClient == nil && signalingClient == nil {
            startVideoStream()
        } else {
            signalingClient?.webrtc?.attachVideoToView(videoView)
        }
    }
    
    func startVideoStream() {
    
        if Savant.control().connectionState == .Local {
            cameraClient = CameraRestClient(delegate: videoView)
            if let url = homeMonitor.endpointURL {
                cameraClient?.connectToUrl(url.absoluteString)
            }
        } else if Savant.control().connectionState == .Cloud {
            signalingClient = SignalingClient(monitor: homeMonitor)
            signalingClient?.delegate = self
            signalingClient?.startSession()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height {
            videoView.videoResizeMode = VideoResizeMode.AspectFill
            resetHUDTimer()
        } else {
            videoView.videoResizeMode = VideoResizeMode.AspectFit
            cancelHUDTimer()
            setHUDHidden(false, animated: true)
        }
        zoomer.zoomScale = 1
        zoomer.contentOffset = CGPoint(x:0,y:0)
    }
    
    func signalingClientReadyToAttachVideo(signalingClient: SignalingClient) {
        signalingClient.webrtc?.attachVideoToView(videoView)
    }
    
    func signalingClient(signalingClient: SignalingClient, disconnectedWithError error: NSError) {
        //TODO present error to user
    }
    
    func resetHUDTimer() {
        cancelHUDTimer()
        hudTimer = NSTimer.scheduledTimerWithTimeInterval(kHUDTimeout, target: self, selector: Selector("hudTimerFired"), userInfo: nil, repeats: false)
    }
    
    func cancelHUDTimer() {
        hudTimer?.invalidate()
        hudTimer = nil
    }
    
    func hudTimerFired() {
        setHUDHidden(true, animated:true)
    }
    
    func setupLivePill() {
        livePill = UILabel()
        livePill.setTranslatesAutoresizingMaskIntoConstraints(false)
        livePill.text = NSLocalizedString("LIVE", comment:"")
        livePill.font = Fonts.caption1
        livePill.textAlignment = .Center
        livePill.backgroundColor = Colors.color6shade1.colorWithAlphaComponent(0.9)
        livePill.textColor = Colors.color1shade1
        livePill.layer.cornerRadius = 12
        livePill.clipsToBounds = true
        livePill.opaque = false
        
        view.addSubview(livePill)
    }
    
    func setupNavBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        navBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.4), Colors.color5shade1.colorWithAlphaComponent(0.0)])
        view.addSubview(navBar)
        view.sav_pinView(navBar, withOptions: .ToTop | .Horizontally)
        view.sav_setHeight(Sizes.row * 8, forView: navBar, isRelative: false)
        
        prompt.prompt.text = homeMonitor.zoneName?.uppercaseString
        prompt.title.text = homeMonitor.name?.uppercaseString
        
        navBar.addSubview(prompt)
        navBar.sav_pinView(prompt, withOptions: .CenterX)
        navBar.sav_pinView(prompt, withOptions: .CenterY)
        
        protectButton = SCUButton(style: .Light, image: UIImage(named: "protect"))
        if homeMonitor.mode == .Sense {
            protectButton.image = UIImage(named: "sense")
        }
        protectButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        protectButton.target = self;
        protectButton.releaseAction = Selector("toggleProtect")
        
        navBar.addSubview(protectButton)
        navBar.sav_pinView(protectButton, withOptions: .CenterY)
        navBar.sav_pinView(protectButton, withOptions: .ToRight, withSpace: Sizes.row * 2)
        
        let doneButton = SCUButton(style: .Light, title: "DONE")
        doneButton?.titleLabel?.font = Fonts.caption1
        doneButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        doneButton.target = self
        doneButton.releaseAction = Selector("donePressed")
        
        navBar.addSubview(doneButton)
        navBar.sav_pinView(doneButton, withOptions: .CenterY)
        navBar.sav_pinView(doneButton, withOptions: .ToLeft, withSpace: Sizes.row * 2)
    }
    
    func setupBottomBar() {
        bottomBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.0), Colors.color5shade1.colorWithAlphaComponent(0.4)])
        view.addSubview(bottomBar)
        view.sav_pinView(bottomBar, withOptions: .ToBottom | .Horizontally)
        view.sav_setHeight(Sizes.row * 8, forView: bottomBar, isRelative: false)
        
        
        actionsButton = SCUButton(style: .Light, title: "ACTIONS")
        actionsButton?.titleLabel?.font = Fonts.caption1
        actionsButton.frame = CGRect(x: 0, y: 0, width: Sizes.row * 21, height: Sizes.row * 5)
        actionsButton.layer.cornerRadius = actionsButton.frame.size.height / 2
        actionsButton.layer.borderWidth = 1
        actionsButton.layer.borderColor = Colors.color1shade1.CGColor
        actionsButton.target = self
        actionsButton.releaseAction = Selector("actionsPressed")
        
        bottomBar.addSubview(actionsButton)
        bottomBar.sav_pinView(actionsButton, withOptions: .CenterX)
        bottomBar.sav_pinView(actionsButton, withOptions: .CenterY)
        bottomBar.sav_setWidth(Sizes.row * 21, forView: actionsButton, isRelative: false)
        bottomBar.sav_setHeight(Sizes.row * 5, forView: actionsButton, isRelative: false)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
        navigationController?.setNavigationBarHidden(true, animated: false)
        registerForAppNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        navigationController?.setNavigationBarHidden(false, animated: false)
        unregisterFromAppNotifications()
       
    }
    
    func registerForAppNotifications() {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.detachAndHangup()
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.startVideo()
        }
        Savant.control().addSystemStatusObserver(self)
    }
    
    func unregisterFromAppNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        Savant.control().removeSystemStatusObserver(self)
    }
    
    
    func connectionIsReady() {
        self.startVideo()
    }
    
    
    override internal func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        zoomer.frame = view.bounds
        videoView.frame = zoomer.bounds
        
        var blurFrame = CGRectZero
        if let imageSize = videoView.previewImageView?.image?.size {
            let widthToHeightRatio = imageSize.height / imageSize.width
            blurFrame.size.width = view.bounds.size.width
            blurFrame.size.height = blurFrame.size.width * widthToHeightRatio
        }
        blurView.frame = blurFrame
        blurView.center = view.center
        
        layoutLivePill()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutLivePill()
        if view.bounds.size.width > view.bounds.size.height {
            resetHUDTimer()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue);
    }
    
    func toggleProtect() {
        let wasInSenseMode = homeMonitor.mode == .Sense
        if wasInSenseMode {
            homeMonitor.updateMonitorMode(.Protect)
            protectButton.image = UIImage(named: "protect")
        } else {
            homeMonitor.updateMonitorMode(.Sense)
            protectButton.image = UIImage(named: "sense")
        }
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.blurView.alpha = wasInSenseMode ? 0.0 : 1.0
            self.senseLabel.alpha = wasInSenseMode ? 0.0 : 1.0
        })
    }
    
    func actionsPressed() {
        let buttonTitles = ["Sound Alarm", "Talk", "Snooze Notifications"]
        actionSheet = SCUActionSheet(buttonTitles: buttonTitles)
        
        actionSheet?.maximumTableHeightPercentage = 0.75
        actionSheet?.showTableSeparatorLines = true
        actionSheet?.titleFont = Fonts.caption1
        actionSheet?.titleTextColor = SCUColors.shared().color03shade06
        
        actionSheet?.buttonFont = Fonts.body
        actionSheet?.buttonTextColor = Colors.color1shade1
        actionSheet?.buttonTextSelectedColor = SCUColors.shared().color01
        
        actionSheet?.cancelButtonFont = Fonts.caption1
        actionSheet?.cancelTextColor = SCUColors.shared().color03shade06
        
        actionSheet?.cancelBackgroundSelectedColor = UIColor.clearColor()
        actionSheet?.buttonBackgroundColor = UIColor.clearColor()
        actionSheet?.buttonBackgroundSelectedColor = UIColor.clearColor()
        actionSheet?.cancelBackgroundColor = UIColor.clearColor()
        actionSheet?.separatorColor = UIColor.clearColor()
        
        let gradient = SCUGradientView(frame: CGRectZero, andColors: [SCUColors.shared().color03.colorWithAlphaComponent(0.1), SCUColors.shared().color03])
        gradient.locations = [0, 0.8]
        actionSheet?.maskingView = gradient
    
        actionSheet?.delegate = self
        actionSheet?.showInView(view)
    }
    
    func startVideo() {
        if cameraClient == nil && signalingClient == nil {
            if Savant.control().connectionState == .Local {
                cameraClient = CameraRestClient(delegate: videoView)
                if let url = homeMonitor.endpointURL {
                    cameraClient?.connectToUrl(url.absoluteString)
                }
            } else if Savant.control().connectionState == .Cloud {
                signalingClient = SignalingClient(monitor: homeMonitor)
                signalingClient?.delegate = self
                signalingClient?.startSession()
            }
        }
    }
    
    func detachAndHangup() {
        videoView.previewImageView.hidden = false
        livePill.hidden = true
        videoView.detachVideo()
        cameraClient?.hangup()
        cameraClient = nil
        signalingClient?.hangup()
        signalingClient = nil
        
    }
    
    func donePressed() {
        if isBorrowingLiveStream {
            videoView.detachVideo()
            signalingClient?.delegate = nil
        } else {
            detachAndHangup()
            videoView.detachVideo()
        }
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setHUDHidden(hidden:Bool, animated:Bool) {
        let block = { () -> Void in
            self.navBar.alpha = hidden ? 0.0 : 1.0
            self.bottomBar.alpha = hidden ? 0.0 : 1.0
        }
        if animated {
            UIView.animateWithDuration(0.2, animations: block)
        } else {
            block()
        }
    }
    
    func videoTap(gestureRecognizer:UITapGestureRecognizer) {
        let shouldHide = navBar.alpha == 1.0
        setHUDHidden(shouldHide, animated:true)
        if !shouldHide {
            if view.bounds.size.width > view.bounds.size.height {
                resetHUDTimer()
            }
        }
    }
    
    func videoDoubleTap(gestureRecognizer:UITapGestureRecognizer) {
        if zoomer.zoomScale > 1 {
            zoomer.zoomToRect(videoView.bounds, animated: true)
        } else {
            let point = gestureRecognizer.locationInView(videoView)
            var frame = videoView.bounds
            frame.size.width /= 2.0
            frame.size.height /= 2.0
            frame.origin.x = point.x - (frame.size.width / 2.0)
            frame.origin.y = point.y - (frame.size.height / 2.0)
            
            zoomer.zoomToRect(frame, animated: true)
        }
    }
    
    func actionSheet(actionSheet: SCUActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        actionSheet.delegate = nil
        self.actionSheet = nil
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return videoView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        layoutLivePill()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        layoutLivePill()
    }
    
    func videoView(videoView: SAVVideoView!, didChangeVideoSize size: CGSize) {
        layoutLivePill()
    }
    
    func layoutLivePill() {
        let isShowingVideo = videoView.visibleVideoView().frame.size.height > 0
        if (!isShowingVideo) {
            livePill.hidden = true
        } else {
            livePill.hidden = (homeMonitor.mode == .Sense)
            let frame = videoView.visibleVideoView().frame
            let point = CGPointMake(0, frame.size.height)
            let translatedPoint = view.convertPoint(point, fromView:videoView.visibleVideoView())
            var bottomLine = view.frame.size.height - translatedPoint.y
            if bottomLine < 0 { bottomLine = 0 }
            
            var pillFrame = CGRectZero;
            pillFrame.size.width = Sizes.row * 7
            pillFrame.size.height = Sizes.row * 3
            pillFrame.origin.x = Sizes.row * 3
            pillFrame.origin.y = view.frame.size.height - bottomLine - (Sizes.row * 3) - pillFrame.size.height
            
            livePill.frame = pillFrame
        }
        
    }
}
