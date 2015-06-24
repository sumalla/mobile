//
//  CameraViewController.swift
//  Prototype
//
//  Created by Joseph Ross on 3/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

@objc public class HomeMonitorDetailViewController: UITableViewController, SignalingClientDelegate, CameraRestClientDelegate, SAVVideoViewDelegate {
  
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))
    
    var videoView:SAVVideoView! = nil
    var blurView:UIVisualEffectView! = nil
    var cameraClient:CameraRestClient? = nil
    var signalingClient:SignalingClient? = nil
    var homeMonitor:HomeMonitor! = nil
    var senseLabel:UILabel! = nil
    var videoCell:UITableViewCell? = nil
    var videoClipEvents:[VideoClipEvent]? = nil
    var liveOverlay:UILabel! = nil
    
    init(homeMonitor monitor:HomeMonitor) {
        super.init(style: UITableViewStyle.Plain)
        homeMonitor = monitor
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName:nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = prompt
        prompt.title.text = homeMonitor.name?.uppercaseString
        prompt.prompt.text = homeMonitor.zoneName?.uppercaseString
        navigationItem.rightBarButtonItem = protectButton()
        
        videoView = SAVVideoView()
        videoView.delegate = self
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        blurView.alpha = 0
        
        senseLabel = UILabel()
        senseLabel.numberOfLines = 2
        senseLabel.textColor = Colors.color1shade1
        senseLabel.text = NSLocalizedString("Camera will not record\n while in Sense mode.", comment:"")
        
        liveOverlay = UILabel()
        liveOverlay.text = NSLocalizedString("LIVE", comment:"")
        liveOverlay.font = Fonts.caption1
        liveOverlay.textAlignment = .Center
        liveOverlay.backgroundColor = Colors.color6shade1.colorWithAlphaComponent(0.9)
        liveOverlay.textColor = Colors.color1shade1
        liveOverlay.layer.cornerRadius = Sizes.row * 3 / 2.0
        liveOverlay.clipsToBounds = true
        liveOverlay.opaque = false
        
        startLiveVideo()
        homeMonitor.fetchVideoClipEvents { (videoClipEvents:[VideoClipEvent]) -> Void in
            self.videoClipEvents = videoClipEvents
        }
    }
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        signalingClient?.webrtc?.attachVideoToView(videoView)
        let blurredImage = homeMonitor.snapshot?.applySavantBlur()
        navigationController?.navigationBar.setBackgroundImage(blurredImage, forBarMetrics: UIBarMetrics.Default)
    }
    
    func reattachVideoView() {
        signalingClient?.delegate = self
        videoCell?.contentView.insertSubview(videoView, belowSubview: blurView)
        videoCell?.contentView.sav_addFlushConstraintsForView(videoView)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        videoView.detachVideo()
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isVideoRow(indexPath) {
            return cellForVideoRow()
        } else {
            let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "VideoClipEvent")
            if let videoClipEvent = videoClipEvents?[indexPath.row] {
                cell.textLabel?.text = videoClipEvent.title
                cell.detailTextLabel?.text = "\(videoClipEvent.videoClips.count) clips"
            }
            return cell
        }
    }
    
    func cellForVideoRow() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.clipsToBounds = true
        cell.selectionStyle = .None
        cell.backgroundColor = UIColor.clearColor()
        let backgroundView = UIImageView(image: homeMonitor.snapshot)
        backgroundView.contentMode = .ScaleAspectFill
        cell.contentView.addSubview(backgroundView)
        cell.contentView.sav_addFlushConstraintsForView(backgroundView)
        cell.contentView.addSubview(videoView)
        videoView.videoResizeMode = .AspectFill
        cell.contentView.sav_addFlushConstraintsForView(videoView)
        cell.contentView.addSubview(blurView)
        cell.contentView.sav_addFlushConstraintsForView(blurView)
        cell.contentView.addSubview(senseLabel)
        cell.contentView.sav_addCenteredConstraintsForView(senseLabel)
        cell.contentView.addSubview(liveOverlay)
        cell.contentView.sav_setHeight(Sizes.row * 3, forView: liveOverlay, isRelative: false)
        cell.contentView.sav_setWidth(Sizes.row * 7, forView: liveOverlay, isRelative: false)
        cell.contentView.sav_pinView(liveOverlay, withOptions: .ToLeft | .ToBottom, withSpace: Sizes.row * 3)
        
        if homeMonitor.mode == .Sense {
            blurView.alpha = 1
            senseLabel.alpha = 1
            liveOverlay.alpha = 0
        } else {
            blurView.alpha = 0
            senseLabel.alpha = 0
            liveOverlay.alpha = isVideoLive() ? 1 : 0
        }
        videoCell = cell
        return cell
    }
    
    func isVideoRow(indexPath:NSIndexPath) -> Bool {
        if indexPath.section == 0 && indexPath.row == 0 {
            return true
        } else {
            return false
        }
    }
    
    func isVideoLive() -> Bool {
        return videoView.remoteVideoSize.height > 0 && videoView.remoteVideoSize.width > 0
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isVideoRow(indexPath) {
            let screenWidth = UIScreen.mainScreen().bounds.width
            let videoHeight = screenWidth / (16.0 / 9)
            return videoHeight
        } else {
            return tableView.rowHeight
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return videoClipEvents?.count ?? 0
        }
    }
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if isVideoRow(indexPath) {
            videoTapped()
        } else {
            if let videoClipEvent = videoClipEvents?[indexPath.row] {
                let clipPlayer = ClipPlayerController(homeMonitor:homeMonitor, videoClipEvent:videoClipEvent)
                navigationController?.pushViewController(clipPlayer, animated: true)
            }
        }
    }
    
    private func protectButton() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(named: "ProtectToggle"), style: .Plain, target: self, action: "toggleProtect")
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func toggleProtect() {
        if homeMonitor.mode == .Sense {
            homeMonitor.updateMonitorMode(.Protect)
        } else {
            homeMonitor.updateMonitorMode(.Sense)
        }
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            let senseOverlayAlpha:CGFloat = self.homeMonitor.mode == .Sense ? 1 : 0
            self.blurView.alpha = senseOverlayAlpha
            self.senseLabel.alpha = senseOverlayAlpha
            self.liveOverlay.alpha = (self.isVideoLive()) ? 1 - senseOverlayAlpha : 0
        })
        
    }
    
    func refreshActivity() {
        tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
    }
    
    func startLiveVideo() {
        if Savant.control().connectionState == .Local {
            cameraClient = CameraRestClient(delegate: self)
            if let url = homeMonitor.endpointURL {
                cameraClient?.connectToUrl(url.absoluteString)
            }
        } else if Savant.control().connectionState == .Cloud {
            signalingClient = SignalingClient(monitor: homeMonitor)
            signalingClient?.delegate = self
            signalingClient?.startSession()
        }
    }
    
    
    public func videoView(videoView: SAVVideoView!, didChangeVideoSize videoSize: CGSize) {
        let liveOverlayAlpha:CGFloat = self.homeMonitor.mode != .Sense && isVideoLive() ? 1 : 0
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.liveOverlay.alpha = liveOverlayAlpha
        })
    }
    
    func signalingClientReadyToAttachVideo(signalingClient: SignalingClient) {
        signalingClient.webrtc?.attachVideoToView(videoView)
    }
    
    
    public func cameraRestClientReadyToAttachVideo(cameraRestClient:CameraRestClient) {
        cameraRestClient.attachVideoToView(videoView)
    
    }
    
    func signalingClient(signalingClient: SignalingClient, disconnectedWithError error: NSError) {
        //TODO
    }
    
    public override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if parent == nil {
            detachAndHangup()
        }
    }
    
    func videoTapped() {
        let liveView = HomeMonitorLiveViewController(homeMonitor: homeMonitor, cameraClient:cameraClient, signalingClient:signalingClient)
        self.presentViewController(liveView, animated: true, completion: nil)
    }
    
    deinit {
        detachAndHangup()
    }
    
    func detachAndHangup() {
        videoView.detachVideo()
        cameraClient?.hangup()
        cameraClient = nil
        signalingClient?.hangup()
        signalingClient = nil
    }
    
    public override func shouldAutorotate() -> Bool {
        return false
    }
    
    public override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.Portrait.rawValue
    }

}
