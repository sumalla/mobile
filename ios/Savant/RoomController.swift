//
//  RoomController.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class RoomController: UIViewController, SCUDrawerViewControllerParallaxDelegate {

    let room: SAVRoom?
    let panGesture: UIPanGestureRecognizer
    let swipeGesture = UISwipeGestureRecognizer()
    let roomImageView = UIImageView()
    var hasAnimated: Bool = false
    var roomImage: UIImage? {
        didSet {
            if let roomImage = roomImage {
                roomImageView.image = roomImage
            } else {
                roomImageView.image = nil
            }
        }
    }
    let coordinator: CoordinatorReference<InterfaceState>
    var observer: AnyObject?
    let grabber = Grabber(frame: CGRectMake(0, 0, 30, 0))
    let grabberPadding = UIView()
    let captureView = UIView()
    let maskContainer = UIView()
    let gradientLayer: CAGradientLayer = CAGradientLayer()
    
    var line: UIView!
    var serviceSelector: ServiceSelectorViewController!
    var roomLabel: UILabel!
    var topBar: UIView!

    var sampleLabel: UILabel!
    var sampleTimeLabel: UILabel!

    required init(room r: SAVRoom?, coordinator c: CoordinatorReference<InterfaceState>, panGesture p: UIPanGestureRecognizer) {
        room = r
        coordinator = c
        panGesture = p

        super.init(nibName: nil, bundle: nil)

        swipeGesture.direction = .Down
        swipeGesture.addTarget(self, action: Selector("handleSwipe:"))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if observer != nil {
            Savant.images() .removeObserver(observer)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        if (hasAnimated)
        {
            self.roomLabel.alpha = 1
            self.line.alpha = 1
            self.serviceSelector.view.alpha = 1
            self.sampleTimeLabel.alpha = 1
            self.sampleLabel.alpha = 1
        }

        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        
        UIView.animateKeyframesWithDuration(0.025, delay: 0, options: nil, animations: { () -> Void in
            self.roomLabel.alpha = 0
            self.sampleLabel.alpha = 0
            self.sampleTimeLabel.alpha = 0
            self.line.alpha = 0
            self.serviceSelector.view.alpha = 0
            }) { (finished:Bool) -> Void in
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        topBar.removeGestureRecognizer(panGesture)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        view.backgroundColor = SCUColors.shared().color03

        roomImageView.contentMode = .ScaleAspectFill
        roomImageView.clipsToBounds = false
        view.addSubview(roomImageView)
        roomImageView.frame = view.frame

        if let room = room where observer == nil {
            observer = Savant.images().addObserverForKey(room.roomId, type: .RoomImage, size: .Large, blurred: true) { [unowned self] image, isDefault in
                self.roomImage = image
            }
        } else {
            if let path = NSBundle.mainBundle().pathForResource("whole-home", ofType: "jpg") {
                roomImage = UIImage(contentsOfFile: path)
            }
        }

        let layout = SCUPagingHorizontalFlowLayout()

        if UIDevice.isPad() {
            layout.numberOfColums = 5
            layout.interSpace = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
            layout.pageInset = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
        } else {
            layout.numberOfColums = 4
            layout.interSpace = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
            layout.pageInset = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2
        }

        let serviceSelector = ServiceSelectorViewController(collectionViewLayout: layout)
        serviceSelector.model = ServiceSelectorModel(room: room)

        if let dc = drawerController, cv = serviceSelector.collectionView {
            dc.setupGestureRecognizerCompatibility([cv.panGestureRecognizer], compatibilityMode: .PreferClient)
            dc.parallaxIntensity = 4
            dc.parallaxDelegate = self
        }

        sav_addChildViewController(serviceSelector)
        view.addSubview(serviceSelector.view)
        view.sav_pinView(serviceSelector.view, withOptions: .ToBottom | .Horizontally)
        view.sav_setHeight(Sizes.row * 17, forView: serviceSelector.view, isRelative: false)
        serviceSelector.view.alpha = 0
        self.serviceSelector = serviceSelector

        let line = UIView.sav_viewWithColor(Colors.color1shade4)
        view.addSubview(line)
        view.sav_pinView(line, withOptions: .Horizontally)
        view.sav_pinView(line, withOptions: .ToTop, ofView: serviceSelector.view, withSpace: 0)
        view.sav_setHeight(1, forView: line, isRelative: false)
        line.alpha = 0
        self.line = line

        let roomLabel = LeftAlignedLabel()
        roomLabel.text = (room != nil) ? room?.roomId : NSLocalizedString("Home", comment: "")
        roomLabel.textColor = Colors.color1shade1
        roomLabel.font = Fonts.subHeadline1
        roomLabel.alpha = 0
        roomLabel.numberOfLines = 0
        self.roomLabel = roomLabel

        let sampleLabel = UILabel()
        sampleLabel.text = "Jerry, George, and Kramer\nleft the home"
        sampleLabel.textColor = Colors.color1shade1
        sampleLabel.font = Fonts.body
        sampleLabel.numberOfLines = 0
        sampleLabel.alpha = 0
        self.sampleLabel = sampleLabel
        
        let sampleTimeLabel = LeftAlignedLabel()
        sampleTimeLabel.text = "TODAY  9:00 AM"
        sampleTimeLabel.textColor = SCUColors.shared().color03shade07
        sampleTimeLabel.font = Fonts.caption2
        sampleTimeLabel.numberOfLines = 0
        sampleTimeLabel.alpha = 0
        self.sampleTimeLabel = sampleTimeLabel

        view.addSubview(maskContainer)
        view.sav_pinView(maskContainer, withOptions: .ToBottom)
        view.sav_pinView(maskContainer, withOptions: .Horizontally, withSpace: 0)
        view.sav_pinView(maskContainer, withOptions: .ToTop)
        
        maskContainer.addSubview(roomLabel)
        maskContainer.addSubview(sampleLabel)
        maskContainer.addSubview(sampleTimeLabel)

        maskContainer.sav_pinView(roomLabel, withOptions: .ToBottom, withSpace: Sizes.row * 37)
        maskContainer.sav_pinView(roomLabel, withOptions: .Leading, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        maskContainer.sav_pinView(roomLabel, withOptions: .Trailing, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()))
        maskContainer.addConstraints(NSLayoutConstraint.sav_constraintsWithMetrics(["maxHeight": Sizes.row * 15], views: ["room": roomLabel], formats: ["room.height <= maxHeight @1000"]))
        
        maskContainer.addSubview(sampleLabel)
        maskContainer.sav_pinView(sampleLabel, withOptions: .ToBottom, withSpace: Sizes.row * 29)
        maskContainer.sav_pinView(sampleLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)

        maskContainer.addSubview(sampleTimeLabel)
        maskContainer.sav_pinView(sampleTimeLabel, withOptions: .ToBottom, withSpace: Sizes.row * 25)
        maskContainer.sav_pinView(sampleTimeLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        
        var topBar = UIView()
        view.addSubview(topBar)
        view.sav_setHeight(Sizes.row * 6, forView: topBar, isRelative: false)
        view.sav_pinView(topBar, withOptions: .ToTop | .Horizontally, withSpace: 20)

        var deviceButton = SCUButton(style: .Light, title: NSLocalizedString("DEVICES", comment: ""))
        deviceButton.target = self
        deviceButton.releaseAction = "showDevices"
        deviceButton.color = Colors.color1shade3
        deviceButton.titleLabel?.font = Fonts.caption1

        topBar.addSubview(deviceButton)
        topBar.sav_pinView(deviceButton, withOptions: .CenterY | .ToLeft)

        var scenesButton = SCUButton(style: .Light, title: NSLocalizedString("SCENES", comment: ""))
        scenesButton.target = self
        scenesButton.releaseAction = "showScenes"
        scenesButton.color = Colors.color1shade3
        scenesButton.titleLabel?.font = Fonts.caption1

        topBar.addSubview(scenesButton)
        topBar.sav_pinView(scenesButton, withOptions: .CenterY | .ToRight)

        topBar.addSubview(grabber)
        topBar.sav_addCenteredConstraintsForView(grabber)

        topBar.addSubview(grabberPadding)
        topBar.sav_pinView(grabberPadding, withOptions: .Vertically | .CenterX)
        topBar.sav_setWidth(100, forView: grabberPadding, isRelative: false)
        topBar.alpha = 0
        self.topBar = topBar

        var tapGesture = UITapGestureRecognizer()
        grabberPadding.addGestureRecognizer(tapGesture)

        tapGesture.sav_handler = { [unowned self] (state, point) in
            self.coordinator.transitionToState(.Rooms)
        }

        view.addSubview(captureView)
        view.sav_addFlushConstraintsForView(captureView)
        captureView.opaque = false

        view.bringSubviewToFront(serviceSelector.view)
        view.bringSubviewToFront(topBar)
        
        view.addGestureRecognizer(swipeGesture)
        swipeGesture.requireGestureRecognizerToFail(panGesture)

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        topBar.addGestureRecognizer(panGesture)
        if (!hasAnimated)
        {
            animateElementsIn()
        }
    }

    func animateElementsIn() {

        view.layoutIfNeeded()

        var roomLabelFrameBefore:CGRect = self.roomLabel.frame
        var roomLabelFrameAfter:CGRect = self.roomLabel.frame
        roomLabelFrameBefore.origin.y = CGRectGetHeight(self.view.frame)
        self.roomLabel.frame = roomLabelFrameBefore
        
        var sampleLabelFrameBefore:CGRect = self.sampleLabel.frame
        var sampleLabelFrameAfter:CGRect = self.sampleLabel.frame
        sampleLabelFrameBefore.origin.y = CGRectGetHeight(self.view.frame)
        self.sampleLabel.frame = sampleLabelFrameBefore
        
        var sampleTimeLabelFrameBefore:CGRect = self.sampleTimeLabel.frame
        var sampleTimeLabelFrameAfter:CGRect = self.sampleTimeLabel.frame
        sampleTimeLabelFrameBefore.origin.y = CGRectGetHeight(self.view.frame)
        self.sampleTimeLabel.frame = sampleTimeLabelFrameBefore
        
        var lineFrameBefore:CGRect = self.line.frame
        var lineFrameAfter:CGRect = self.line.frame
        lineFrameBefore.origin.y = CGRectGetHeight(self.view.frame)
        self.line.frame = lineFrameBefore
        
        var serviceSelectorFrameBefore:CGRect = self.serviceSelector.view.frame
        var serviceSelectorFrameAfter:CGRect = self.serviceSelector.view.frame
        serviceSelectorFrameBefore.origin.y = CGRectGetHeight(self.view.frame)
        self.serviceSelector.view.frame = serviceSelectorFrameBefore
        
        gradientLayer.colors = [UIColor.blackColor().colorWithAlphaComponent(1).CGColor,
                                UIColor.blackColor().colorWithAlphaComponent(1).CGColor,
                                UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor,
                                UIColor.blackColor().colorWithAlphaComponent(0).CGColor,
                                UIColor.blackColor().colorWithAlphaComponent(0).CGColor]
        
        gradientLayer.locations = [0, 0.65, 0.8, 0.8, 1]
        gradientLayer.frame = maskContainer.bounds

        maskContainer.layer.addSublayer(gradientLayer)
        maskContainer.layer.mask = gradientLayer
        
        var duration = 0.4
        
        self.serviceSelector.view.alpha = 0
        self.line.alpha = 0
        self.roomLabel.alpha = 0
        self.sampleLabel.alpha = 0
        self.sampleTimeLabel.alpha = 0
        self.topBar.alpha = 0
        
        UIView.animateWithDuration(duration, delay: 0.2, usingSpringWithDamping: 0.98, initialSpringVelocity: 15, options: nil, animations: { () -> Void in
            self.roomLabel.frame = roomLabelFrameAfter
            self.sampleLabel.frame = sampleLabelFrameAfter
            self.sampleTimeLabel.frame = sampleTimeLabelFrameAfter
            self.sampleLabel.alpha = 1
            self.sampleTimeLabel.alpha = 1
            self.roomLabel.alpha = 1
            self.topBar.alpha = 1
            }, completion: nil)

        
        UIView.animateWithDuration(duration, delay: 0.1, usingSpringWithDamping: 0.98, initialSpringVelocity: 15, options: nil, animations: { () -> Void in
            self.line.frame = lineFrameAfter
            self.line.alpha = 1
            
            }, completion: nil)
        
        UIView.animateWithDuration(duration, delay: 0.14, usingSpringWithDamping: 0.98, initialSpringVelocity: 15, options: nil, animations: { () -> Void in
            self.serviceSelector.view.frame = serviceSelectorFrameAfter
            self.serviceSelector.view.alpha = 1
            
            }, completion: nil)
        
        hasAnimated = true
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition({ _ in
            var f = self.roomImageView.frame
            f.size = size
            self.roomImageView.frame = f
        }, completion: nil)
    }
    
    func addParallaxEffectsForDrawer(drawer: SCUDrawerViewController) -> UIView {
        return self.roomImageView
    }
    
    func transitionToRooms() {
        coordinator.transitionToState(.Rooms)
    }

    func showScenes() {
        coordinator.transitionToState(.Scenes(room))
    }

    func showDevices() {
        coordinator.transitionToState(.Devices(room))
    }

    func handleSwipe(recognizer: UISwipeGestureRecognizer) {
        if recognizer.state == .Ended {
            transitionToRooms()
        }
    }
}
