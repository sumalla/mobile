//
//  HomeUserAuthenticationTableController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class HomeUserAuthenticationViewController: FakeNavBarViewController {

    private let coordinator: CoordinatorReference<HomePickerState>
    private let user: SAVLocalUser
    let passwordField = ErrorTextField(style: .Dark)
    let signInButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Sign In", comment: ""))
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    let container = UIView(frame: CGRectZero)
    let scrollView = UIScrollView(frame: CGRectZero)
    var keyboardHeight: CGFloat = 216
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    init(coordinator c: CoordinatorReference<HomePickerState>, user u: SAVLocalUser) {
        coordinator = c
        user = u
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)

        signInButton.color = Colors.color3shade2
        signInButton.layer.borderColor = Colors.color3shade2.CGColor
        
        title = user.accountName.uppercaseString
        
        view.addSubview(container)
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, Sizes.row * 30), forView: container, isRelative: false)
        view.sav_pinView(container, withOptions: .CenterX | .CenterY)
        
        container.backgroundColor = Colors.color1shade1
        container.layer.cornerRadius = 4.0
        
        view.addSubview(scrollView)
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, Sizes.row * 30), forView: scrollView, isRelative: false)
        view.sav_pinView(scrollView, withOptions: .CenterX | .CenterY)

        signInButton.target = self
        signInButton.releaseAction = "attemptSignIn"

        passwordField.placeholder = NSLocalizedString("password", comment: "")
        passwordField.textField.secureTextEntry = true

        passwordField.validationHandler = {
            if $0.isEmpty {
                return NSLocalizedString("Enter your password", comment: "").uppercaseString
            }

            return nil
        }
        
        passwordField.beginHandler = { [weak self] in
            self?.adjustForView(signInButton)
        }

        passwordField.returnHandler = { [weak self] in
            self?.attemptSignIn()
        }
        
        scrollView.addSubview(passwordField)
        scrollView.addSubview(signInButton)
        scrollView.addSubview(spinner)

        scrollView.sav_pinView(passwordField, withOptions: .ToTop, withSpace: Sizes.row * 8)
        scrollView.sav_pinView(passwordField, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)
        scrollView.sav_setWidth(0.9, forView: passwordField, isRelative: true)

        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)

        scrollView.sav_pinView(signInButton, withOptions: .CenterX, withSpace: 0)
        scrollView.sav_pinView(signInButton, withOptions: .ToTop, withSpace: Sizes.row * 19)
        scrollView.sav_setSize(buttonSize, forView: signInButton, isRelative: false)

        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: signInButton, withSpace: 0)
        spinner.hidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: "handleTap")
        scrollView.addGestureRecognizer(tap)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        passwordField.textField.becomeFirstResponder()
    }
    
    func handleTap() {
        if passwordField.textField.isFirstResponder() {
            passwordField.textField.resignFirstResponder()
        }
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

    func attemptSignIn() {
        if passwordField.validate() {
            signIn()
        }
    }

    private func signIn() {
        setEditing(false, animated: true)
        signInButton.hidden = true
        spinner.hidden = false
        spinner.startAnimating()
        Savant.control().loginToLocalUser(user.accountName, password: passwordField.text!)
    }

    
    func handleSignInError() {
        NSTimer.sav_scheduledBlockWithDelay(0.5) {
            self.passwordField.errorText = NSLocalizedString("Incorrect password", comment: "").uppercaseString
            self.signInButton.hidden = false
            self.spinner.hidden = true
            self.spinner.stopAnimating()
        }
    }

    override func handleBack() {
        navigationController?.popViewControllerAnimated(true)
    }

}

