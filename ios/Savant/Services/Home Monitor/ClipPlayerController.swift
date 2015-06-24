//
//  ClipPlayerController.swift
//  Savant
//
//  Created by Joseph Ross on 4/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import MediaPlayer

class ClipPlayerController: UIViewController, UIGestureRecognizerDelegate {
    var homeMonitor:HomeMonitor! = nil
    var videoClipEvent:VideoClipEvent! = nil
    var videoPlayers:[MPMoviePlayerController] = []
    var videoIndex:Int = 0
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))
    var topBar:SCUGradientView! = nil
    var bottomBar:SCUGradientView! = nil
    var sliderArray:[UISlider] = []
    var timeLabel:UILabel! = nil
    var clipLabel:UILabel? = nil
    var menuButton:SCUButton! = nil
    var videoTapRecognizer:UITapGestureRecognizer! = nil
    var playbackTimer:NSTimer? = nil
    var playPauseButton:SCUButton! = nil
    
    var hudTimer:NSTimer? = nil
    let kHUDTimeout = 5.0 //seconds
    
    init(homeMonitor:HomeMonitor, videoClipEvent:VideoClipEvent) {
        super.init(nibName: nil, bundle: nil)
        self.videoClipEvent = videoClipEvent
        self.homeMonitor = homeMonitor
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    deinit {
        unregisterPlayerNotifications()
    }
    
    override func viewDidLoad() {
        for videoClip in videoClipEvent.videoClips {
            let videoPlayer = MPMoviePlayerController(contentURL: videoClip.videoUrl)
            videoPlayers.append(videoPlayer)
            videoPlayer.controlStyle = .None
            videoPlayer.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        }
        let videoPlayer = currentVideoPlayer()
        view.addSubview(videoPlayer.view)
        view.sav_addFlushConstraintsForView(videoPlayer.view)
        videoTapRecognizer = UITapGestureRecognizer(target: self, action: Selector("videoTapped"))
        videoTapRecognizer.delegate = self
        videoPlayer.view.addGestureRecognizer(videoTapRecognizer)
        videoPlayer.prepareToPlay()
        
        setupTopBar()
        setupBottomBar()
        
        playPauseButton = SCUButton(image: UIImage(named:"pause_clip"))
        playPauseButton.color = Colors.color1shade2
        view.addSubview(playPauseButton)
        view.sav_addCenteredConstraintsForView(playPauseButton)
        playPauseButton.releaseCallback = {
            self.togglePlayback()
        }
        
        resetHUDTimer()
        resetPlaybackTimer()
        registerPlayerNotifications()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        currentVideoPlayer().play()
    }
    
    func setupTopBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        topBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.4), Colors.color5shade1.colorWithAlphaComponent(0.0)])
        view.addSubview(topBar)
        view.sav_pinView(topBar, withOptions: .ToTop | .Horizontally)
        view.sav_setHeight(Sizes.row * 8, forView: topBar, isRelative: false)
        
        prompt.prompt.text = homeMonitor.zoneName?.uppercaseString
        prompt.title.text = homeMonitor.name?.uppercaseString
        
        topBar.addSubview(prompt)
        topBar.sav_pinView(prompt, withOptions: .CenterX)
        topBar.sav_pinView(prompt, withOptions: .CenterY)
        
        let doneButton = SCUButton(style: .Light, title: "DONE")
        doneButton?.titleLabel?.font = Fonts.caption1
        doneButton.frame = CGRect(x: 0, y: 0, width: 0, height: 25)
        doneButton.target = self
        doneButton.releaseAction = Selector("donePressed")
        
        topBar.addSubview(doneButton)
        topBar.sav_pinView(doneButton, withOptions: .CenterY)
        topBar.sav_pinView(doneButton, withOptions: .ToLeft, withSpace: Sizes.row * 2)
    }

    func donePressed() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func setupBottomBar() {
        bottomBar = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.0), Colors.color5shade1.colorWithAlphaComponent(0.4)])
        view.addSubview(bottomBar)
        view.sav_pinView(bottomBar, withOptions: .ToBottom | .Horizontally)
        view.sav_setHeight(Sizes.row * 8, forView: bottomBar, isRelative: false)
        
        timeLabel = UILabel()
        timeLabel.text = "11:30 AM"
        timeLabel.textColor = Colors.color1shade1
        timeLabel.font = Fonts.caption2
        bottomBar.addSubview(timeLabel)
        bottomBar.sav_pinView(timeLabel, withOptions: .ToLeft, withSpace:8)
        bottomBar.sav_pinView(timeLabel, withOptions: .CenterY)
        
        menuButton = SCUButton(image: UIImage(named: "hotdog"))
        menuButton.color = Colors.color1shade1
        bottomBar.addSubview(menuButton)
        bottomBar.sav_pinView(menuButton, withOptions: .ToRight | .CenterY)
        var rightPin:UIView = menuButton
        
        if (videoClipEvent.videoClips.count > 1) {
            clipLabel = UILabel()
            let label = clipLabel!
            label.text = "1 of \(videoClipEvent.videoClips.count)"
            label.textColor = Colors.color1shade1
            label.font = Fonts.caption2
            bottomBar.addSubview(label)
            bottomBar.sav_pinView(label, withOptions: .ToLeft, ofView: menuButton, withSpace:-8)
            bottomBar.sav_pinView(label, withOptions: .CenterY)
            rightPin = label
        }
        
        // Set up sliders based on clip durations
        var leftPin:UIView = timeLabel
        var previousDuration:NSTimeInterval = 0
        var firstSlider = true
        var sliderIndex = 0
        for videoClip in videoClipEvent.videoClips {
            let slider = PlaybackSlider()
            let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("sliderTapped:"))
            slider.addGestureRecognizer(tapRecognizer)
            slider.tag = sliderIndex++
            bottomBar.addSubview(slider)
            slider.maximumTrackTintColor = Colors.color1shade3
            slider.minimumTrackTintColor = Colors.color1shade1
            if firstSlider {
                slider.setThumbImage(thumbImage(), forState: .Normal)
            } else  {
                slider.setThumbImage(UIImage(), forState: .Normal)
            }
            bottomBar.sav_pinView(slider, withOptions: .ToRight, ofView: leftPin, withSpace: 8)
            bottomBar.sav_pinView(slider, withOptions: .CenterY)
            bottomBar.sav_setHeight(20, forView: slider, isRelative: false)
            if let lastSlider = sliderArray.last {
                let ratio = videoClip.duration / previousDuration
                let views = ["current":slider, "previous":lastSlider]
                bottomBar.addCompactConstraint("current.width = previous.width * \(ratio)", metrics: nil, views: views)
            }
            sliderArray.append(slider)
            leftPin = slider
            previousDuration = videoClip.duration
            firstSlider = false
        }
        
        if let lastSlider = sliderArray.last {
            bottomBar.sav_pinView(lastSlider, withOptions: .ToLeft, ofView:rightPin, withSpace: 8)
        }

    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    func registerPlayerNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("videoPlayerPlaybackStateChanged:"), name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("videoPlayerLoadStateChanged:"), name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("videoPlayerPlaybackFinished:"), name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
    }
    
    func unregisterPlayerNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// MARK - MPMoviePlayer notification handlers
    
    func videoPlayerPlaybackStateChanged(notification:NSNotification) {
        if let videoPlayer = notification.object as? MPMoviePlayerController {
            if  videoPlayer == currentVideoPlayer() {
                if videoPlayer.playbackState == .Playing {
                    playPauseButton.image = UIImage(named:"pause_clip")
                } else {
                    playPauseButton.image = UIImage(named:"play_clip")
                }
            }
        }
        
    }
    
    func videoPlayerLoadStateChanged(notification:NSNotification) {
        let videoPlayer = notification.object as? MPMoviePlayerController
    }
    
    func videoPlayerPlaybackFinished(notification:NSNotification) {
        let videoPlayer = notification.object as? MPMoviePlayerController
        if (videoPlayer == currentVideoPlayer()) {
            switchVideoPlayerIndex(videoIndex + 1)
        }
        
    }
    
    func thumbImage() -> UIImage {
        let size = CGSizeMake(10, 10)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        UIColor.whiteColor().setFill()
        let context = UIGraphicsGetCurrentContext()
        CGContextFillEllipseInRect(context, CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func switchVideoPlayerIndex(newIndex:Int) {
        switchVideoPlayerIndex(newIndex, offsetRatio: -1)
    }
    
    func switchVideoPlayerIndex(newIndex:Int, offsetRatio:CGFloat) {
        if newIndex < 0 || newIndex >= videoClipEvent.videoClips.count {
            setHUDHidden(false, animated: true)
            cancelHUDTimer()
            return
        }
        currentVideoPlayer().pause()
        currentVideoPlayer().view.removeFromSuperview()
        currentVideoPlayer().view.removeGestureRecognizer(videoTapRecognizer)
        if (newIndex > videoIndex) {
            currentSlider().value = 1
        } else {
            currentSlider().value = 0
        }
        currentSlider().setThumbImage(UIImage(), forState: .Normal)
        videoIndex = newIndex
        currentSlider().setThumbImage(thumbImage(), forState:.Normal)
        let videoView = currentVideoPlayer().view
        view.insertSubview(videoView, belowSubview:topBar)
        videoView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.sav_addFlushConstraintsForView(videoView)
        videoView.addGestureRecognizer(videoTapRecognizer)
        clipLabel?.text = "\(videoIndex + 1) of \(videoClipEvent.videoClips.count)"
        if (offsetRatio > 0) {
            let offsetTime = NSTimeInterval(offsetRatio) * currentVideoClip().duration
            currentVideoPlayer().initialPlaybackTime = offsetTime
            currentVideoPlayer().currentPlaybackTime = NSTimeInterval(offsetRatio) * currentVideoClip().duration
        } else {
            currentVideoPlayer().initialPlaybackTime = 0
            currentVideoPlayer().currentPlaybackTime = 0
        }
        currentVideoPlayer().play()
        setHUDHidden(false, animated: true)
        resetHUDTimer()
    }
    
    func resetPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("elapsedPlaybackTimerFired"), userInfo: nil, repeats: true)
    }
    
    func elapsedPlaybackTimerFired() {
        let videoPlayer = currentVideoPlayer()
        let sliderRatio = videoPlayer.currentPlaybackTime / currentVideoClip().duration
        currentSlider().value = Float(sliderRatio)
    }
    
    func currentVideoPlayer() -> MPMoviePlayerController {
        return videoPlayers[videoIndex]
    }
    
    func currentSlider() -> UISlider {
        return sliderArray[videoIndex]
    }
    
    func currentVideoClip() -> VideoClip {
        return videoClipEvent.videoClips[videoIndex]
    }
    
    func togglePlayback() {
        let videoPlayer = currentVideoPlayer()
        if videoPlayer.playbackState == .Playing {
            videoPlayer.pause()
            cancelHUDTimer()
            playbackTimer?.invalidate()
            playbackTimer = nil
        } else {
            videoPlayer.play()
            resetHUDTimer()
            resetPlaybackTimer()
        }
    }
    
    func videoTapped() {
        let videoPlayer = currentVideoPlayer()
        if videoPlayer.playbackState == .Playing {
            resetHUDTimer()
        } else {
            cancelHUDTimer()
        }
        let isHidden = playPauseButton.alpha == 0
        setHUDHidden(!isHidden, animated: true)
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
    
    func setHUDHidden(hidden:Bool, animated:Bool) {
        let block = { () -> Void in
            self.topBar.alpha = hidden ? 0.0 : 1.0
            self.bottomBar.alpha = hidden ? 0.0 : 1.0
            self.playPauseButton.alpha = hidden ? 0.0 : 1.0
        }
        if animated {
            UIView.animateWithDuration(0.2, animations: block)
        } else {
            block()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        resetHUDTimer()
        setHUDHidden(false, animated: true)
    }
    
    func sliderTapped(recognizer:UITapGestureRecognizer) {
        resetHUDTimer()
        if let slider = recognizer.view as? UISlider {
            let point = recognizer.locationInView(slider)
            let sliderValue = point.x / slider.bounds.size.width
            if (slider.tag != videoIndex) {
                switchVideoPlayerIndex(slider.tag, offsetRatio:sliderValue)
            } else {
                let videoDuration = currentVideoPlayer().duration
                currentVideoPlayer().currentPlaybackTime = NSTimeInterval(sliderValue) * videoDuration
            }
            elapsedPlaybackTimerFired()
        }
    }
    
    /// MARK - UIGestureRecognizerDelegate implementation
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class PlaybackSlider : UISlider {
    override func trackRectForBounds(bounds: CGRect) -> CGRect {
        var rect = super.trackRectForBounds(bounds)
        rect.size.height = 1.0
        return rect
    }
}
