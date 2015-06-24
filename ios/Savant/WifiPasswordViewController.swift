//
//  WifiPasswordViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class WifiPasswordViewController: FakeNavBarViewController, UIGestureRecognizerDelegate {
    let card = UIView(frame: CGRectZero)
    let topLabel = UILabel(frame: CGRectZero)
    let passwordField = ErrorTextField(style: .Dark)
    let bottomLabel = UILabel(frame: CGRectZero)
    let connectButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Connect", comment: ""))
    let noPasswordButton = SCUButton(style: .UnderlinedText, title: NSLocalizedString("I don't have a Wi-Fi password.", comment: ""))
    let passwordToggleButton = SCUButton(image: UIImage(named: "eye"))
    var passwordHidden: Bool {
        didSet {
            if self.passwordHidden {
                self.passwordToggleButton.color = Colors.color3shade2
            } else {
                self.passwordToggleButton.color = Colors.color3shade1
            }
        }
    }
    let scrollView = UIScrollView(frame: CGRectZero)
    
    var keyboardHeight: CGFloat = 0

    let coordinator:CoordinatorReference<HostOnboardingState>
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    init(coordinator:CoordinatorReference<HostOnboardingState>) {
        self.coordinator = coordinator
        passwordHidden = true
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        connectButton.releaseCallback =  { [unowned self] in
            self.view.endEditing(true)
            if let password = self.passwordField.text {
                self.coordinator.transitionToState(.CheckWifiCredentials(password))
            }
        }
        
        noPasswordButton.releaseCallback =  { [weak self] in
            self?.view.endEditing(true)
            self?.coordinator.transitionToState(.NoWifiPassword)
        }
        
        card.backgroundColor = Colors.color1shade1
        card.layer.cornerRadius = 3
        
        passwordField.textField.secureTextEntry = true
        passwordField.textField.returnKeyType = .Done
        passwordField.textField.keyboardType = .Default
        passwordField.textField.autocorrectionType = .No
        passwordField.textField.autocapitalizationType = .None
        passwordField.placeholder = NSLocalizedString("password", comment: "")
        passwordField.textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        
        passwordField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(connectButton)
            })
        }
        
        passwordField.returnHandler = { [unowned self] in
            self.view.endEditing(true)
            if let password = self.passwordField.text where count(password) > 0 {
                self.coordinator.transitionToState(.CheckWifiCredentials(password))
            } else {
                self.coordinator.transitionToState(.NoWifiPassword)
            }
        }
        
        passwordToggleButton.releaseCallback = { [unowned self] in
            self.passwordField.textField.secureTextEntry = !self.passwordField.textField.secureTextEntry
            
            if self.passwordField.textField.secureTextEntry {
                self.passwordHidden = true
            } else {
                self.passwordHidden = false
            }
            
            self.passwordField.text = self.passwordField.text
        }

        topLabel.numberOfLines = 0
        topLabel.font = Fonts.body
        topLabel.textColor = Colors.color3shade2
        topLabel.textAlignment = .Center
        topLabel.text = NSLocalizedString("Connect Your Wi-Fi", comment: "")
        
        bottomLabel.numberOfLines = 0
        bottomLabel.font = Fonts.caption1
        bottomLabel.textColor = Colors.color3shade2
        bottomLabel.lineBreakMode = .ByWordWrapping
        bottomLabel.textAlignment = .Center
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 12
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: NSLocalizedString("This will allow the host to connect to your Wi-Fi network and communicate with your Savant App.", comment: ""))
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        
        bottomLabel.attributedText = attrString
        passwordToggleButton.color = Colors.color3shade2
        passwordToggleButton.hidden = true
        
        scrollView.delaysContentTouches = false
        scrollView.scrollEnabled = false
        
        view.addSubview(card)
        view.addSubview(scrollView)
        view.addSubview(noPasswordButton)

        scrollView.addSubview(topLabel)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(bottomLabel)
        scrollView.addSubview(connectButton)
        
        passwordField.addSubview(passwordToggleButton)
        
        view.sav_pinView(card, withOptions: .CenterX)
        view.sav_pinView(noPasswordButton, withOptions: .CenterX)
        view.sav_pinView(noPasswordButton, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 6)
        view.sav_pinView(noPasswordButton, withOptions: .ToBottom, withSpace: Sizes.row * 5)
        
        scrollView.sav_pinView(connectButton, withOptions: .CenterX)
        scrollView.sav_pinView(connectButton, withOptions: .ToTop, withSpace: Sizes.row * 36)
        scrollView.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 24, height: Sizes.row * 5), forView: connectButton, isRelative: false)
        
        scrollView.sav_pinView(topLabel, withOptions: .CenterX)
        scrollView.sav_pinView(topLabel, withOptions: .ToTop, withSpace: Sizes.row * 7)
        
        scrollView.sav_pinView(bottomLabel, withOptions: .CenterX)
        scrollView.sav_pinView(bottomLabel, withOptions: .ToTop, withSpace: Sizes.row * 24)
        
        scrollView.sav_pinView(passwordField, withOptions: .CenterX)
        scrollView.sav_pinView(passwordField, withOptions: .ToTop, withSpace: Sizes.row * 14)

        scrollView.sav_setWidth(0.8, forView: topLabel, isRelative: true)
        scrollView.sav_setWidth(0.8, forView: bottomLabel, isRelative: true)
        scrollView.sav_setWidth(0.8, forView: passwordField, isRelative: true)
        
        passwordField.sav_pinView(passwordToggleButton, withOptions: .ToTop, withSpace: Sizes.row)
        passwordField.sav_pinView(passwordToggleButton, withOptions: .ToRight, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)

        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = card.frame
        scrollView.contentSize = scrollView.frame.size
    }
    
    override func phoneConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 11)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, height: Sizes.row * 49), forView: card, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 19)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 46), forView: card, isRelative: false)
    }
    
    override func padPortraitConstraints() {
        view.sav_pinView(card, withOptions: .ToTop, withSpace: Sizes.row * 30)
        view.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, height: Sizes.row * 46), forView: card, isRelative: false)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let height = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().size.height {
                keyboardHeight = height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        adjustForView(nil)
    }
    
    func textFieldDidChange(textField: UITextField) {
        if let text = textField.text where count(text) == 0 {
            passwordToggleButton.hidden = true
        } else {
            passwordToggleButton.hidden = false
        }
    }
    
    func adjustForView(adjustmentView: UIView?) {
        
        var offset: CGFloat = 0.0
        
        if let adjustmentView = adjustmentView {
            let frame = view.convertRect(adjustmentView.frame, fromView: scrollView)
            if CGRectGetMaxY(frame) + scrollView.contentOffset.y > (CGRectGetMaxY(view.frame) - keyboardHeight) {
                let padding = UIDevice.isShortPhone() ? Sizes.row : Sizes.row * 3
                offset = CGRectGetMaxY(frame) - (CGRectGetMaxY(view.frame) - keyboardHeight) + padding + scrollView.contentOffset.y
            }
        }
        
        UIView.animateWithDuration(0.15) {
            self.scrollView.contentOffset.y = offset
        }
    }
    
    override func handleBack() {
        coordinator.transitionToState(.HostFoundWifi(nil))
    }
}

extension WifiPasswordViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view as? ErrorTextField != nil || touch.view.superview as? ErrorTextField != nil || touch.view as? TTTAttributedLabel != nil{
            return false
        } else {
            return true
        }
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
}
