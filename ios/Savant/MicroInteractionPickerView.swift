//
//  MicroInteractionPickerView.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class MicroInteractionPickerView : UIView, MicroInteractionPickerDelegate {
    weak var delegate: MicroInteractionPickerViewDelegate?
    let container = UIView()
    var model: MicroInteractionPickerModel!
    var leftButton  = SCUButton()
    var rightButton	= SCUButton()
    var roomLabel = SCUAnimatedLabel()
    var currentValue: String {
        get {
            return model.currentRoom
        }
    }

    required init(rooms: [String]) {
        super.init(frame: CGRectZero)
        
        self.model = MicroInteractionPickerModel(rooms: rooms, delegate: self)

        self.addSubview(container)
        self.sav_addFlushConstraintsForView(container)

        let chevron = UIImage(named: "chevron-up")
        let leftImage = UIImage(CGImage: chevron?.CGImage, scale: 1.0, orientation: .Left)?.scaleToSize(CGSizeMake(20, 20))
        let rightImage = UIImage(CGImage: chevron?.CGImage, scale: 1.0, orientation: .Right)?.scaleToSize(CGSizeMake(20, 20))
        
        leftButton = SCUButton(style: .Light, image: leftImage)
        rightButton = SCUButton(style: .Light, image: rightImage)
        
        let separatorView = UIView()
        separatorView.backgroundColor = Colors.color3shade3

        roomLabel.userInteractionEnabled = true
        roomLabel.font = Fonts.caption1
        roomLabel.textColor = Colors.color3shade1
        let left = UISwipeGestureRecognizer()
        left.direction = .Right
        let right = UISwipeGestureRecognizer()
        right.direction = .Left
        /* These directions are backwards on purpose */
        
        container.addGestureRecognizer(left)
        container.addGestureRecognizer(right)
        
        leftButton.color = Colors.color3shade2
        leftButton.tintColor = Colors.color3shade2
        leftButton.backgroundColor = UIColor.clearColor()
        leftButton.selectedBackgroundColor = Colors.color3shade3
        leftButton.selectedColor = Colors.color5shade1
        
        rightButton.color = Colors.color3shade2
        rightButton.tintColor = Colors.color3shade2
        rightButton.backgroundColor = UIColor.clearColor()
        rightButton.selectedBackgroundColor = Colors.color3shade3
        rightButton.selectedColor = Colors.color5shade1
        
        leftButton.addTarget(self, action: "handleButtonPress:", forControlEvents: .TouchUpInside)
        rightButton.addTarget(self, action: "handleButtonPress:", forControlEvents: .TouchUpInside)
        
        left.sav_handler = { [unowned self] (state, point) in
            self.handleButtonPress(self.leftButton)
        }
        
        right.sav_handler = { [unowned self] (state, point) in
            self.handleButtonPress(self.rightButton)
        }
        
        container.addSubview(leftButton)
        container.addSubview(roomLabel)
        container.addSubview(rightButton)
        container.addSubview(separatorView)

        container.backgroundColor = Colors.color3shade4
        
        container.sav_setHeight(UIScreen.screenPixel(), forView: separatorView, isRelative: false)
        container.sav_pinView(separatorView, withOptions: .Horizontally | .ToTop)
        
        container.sav_pinView(leftButton, withOptions: .ToLeft | .ToBottom)
        container.sav_pinView(leftButton, withOptions: .ToBottom, ofView: separatorView, withSpace: 0)

        container.sav_pinView(rightButton, withOptions: .ToRight | .ToBottom)
        container.sav_pinView(rightButton, withOptions: .ToBottom, ofView: separatorView, withSpace: 0)

        container.sav_pinView(roomLabel, withOptions: .ToRight, ofView: leftButton, withSpace: 0)
        container.sav_pinView(roomLabel, withOptions: .ToLeft, ofView: rightButton, withSpace: 0)
        container.sav_pinView(roomLabel, withOptions: .ToBottom)
        container.sav_pinView(roomLabel, withOptions: .ToBottom, ofView: separatorView, withSpace: 0)
        container.sav_setWidth(0.5, forView: roomLabel, isRelative: true)
        container.sav_setWidth(0.25, forView: leftButton, isRelative: true)
        container.sav_setWidth(0.25, forView: rightButton, isRelative: true)
        
        self.model?.updateCurrentRoom(.None)
    }
    
    func updateRoomLabel(room: String, direction: PickerDirection) {

        if (direction == .Right) {
            roomLabel.transitionType = .MarqueeLeft
        } else if (direction == .Left) {
            roomLabel.transitionType = .MarqueeRight
        } else {
            roomLabel.transitionType = .None
        }

        if let delegate = delegate {
            delegate.pickerWillSwitchToRoom(room) { [unowned self] in
                self.roomLabel.text = room
            }
        } else {
            roomLabel.text = room
        }
    }

    func handleButtonPress(sender: SCUButton) {
        let direction: PickerDirection = (sender == leftButton) ? .Left : .Right
        self.model?.updateCurrentRoom(direction)
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, Sizes.row * 5)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MicroInteractionPickerViewDelegate: class {
    func pickerWillSwitchToRoom(room: String, completion: () -> ())
}