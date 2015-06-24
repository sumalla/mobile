//
//  SignUpUserProfilePage.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class SignUpUserProfilePage: LandingPageContentBase {

    let email: String
    let password: String

    let firstNameField = ErrorTextField(style: .Dark)
    let lastNameField = ErrorTextField(style: .Dark)
    let createButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Create Account", comment: ""))
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    let container = UIView(frame: CGRectZero)
    let scrollView = UIScrollView(frame: CGRectZero)
    var fieldContainer = UIView(frame: CGRectZero)
    var keyboardHeight: CGFloat = 216
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    init(coordinator c: CoordinatorReference<SignInState>, email e: String, password p: String) {
        email = e
        password = p
        super.init(coordinator: c)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)

        container.backgroundColor = Colors.color1shade1
        container.layer.cornerRadius = 4.0
        
        spinner.hidden = true

        firstNameField.placeholder = NSLocalizedString("first name", comment: "")
        lastNameField.placeholder = NSLocalizedString("last name", comment: "")
        firstNameField.textField.returnKeyType = .Next

        for field in [firstNameField, lastNameField] {
            field.textField.autocorrectionType = .No
        }

        createButton.target = self
        createButton.releaseAction = "attemptCreate"

        let verticalConfiguration = SAVViewDistributionConfiguration()
        verticalConfiguration.interSpace = 0
        verticalConfiguration.vertical = true

        fieldContainer = UIView.sav_viewWithEvenlyDistributedViews([firstNameField, lastNameField], withConfiguration: verticalConfiguration)
        
        view.addSubview(container)
        view.addSubview(scrollView)
        
        view.sav_pinView(container, withOptions: .CenterX)

        scrollView.addSubview(fieldContainer)
        scrollView.addSubview(createButton)
        scrollView.addSubview(spinner)
        
        scrollView.sav_setWidth(0.8, forView: fieldContainer, isRelative: true)
        scrollView.sav_pinView(fieldContainer, withOptions: .CenterX)
        scrollView.sav_pinView(createButton, withOptions: .CenterX)
        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: createButton, withSpace: 0)
        
        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 18, height: Sizes.row * 5)
        scrollView.sav_setSize(buttonSize, forView: createButton, isRelative: false)

        setupConstraints()
        setupHandlers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = container.frame
        scrollView.contentSize = scrollView.frame.size
    }
    
    override func phoneConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, Sizes.row * 47), forView: container, isRelative: false)
        view.sav_pinView(container, withOptions: .ToTop, withSpace: Sizes.row * 12)
    }
    
    override func universalPadConstraints() {
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 26)
        scrollView.sav_pinView(createButton, withOptions: .ToTop, withSpace: Sizes.row * 46)
        view.sav_pinView(container, withOptions: .CenterY)
    }
    
    override func padPortraitConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32, Sizes.row * 58), forView: container, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 28, Sizes.row * 58), forView: container, isRelative: false)
    }
    
    func setupHandlers() {
        
        firstNameField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(firstNameField)
            })
        }
        
        lastNameField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(createButton)
            })
        }
        
        firstNameField.returnHandler = { [weak self] in
            self?.lastNameField.textField.becomeFirstResponder()
        }
        
        lastNameField.returnHandler = { [weak self] in
            self?.attemptCreate()
        }
        
        firstNameField.validationHandler = {
            if $0.isEmpty {
                return ""
            }
            
            return nil
        }
        
        lastNameField.validationHandler = {
            if $0.isEmpty {
                return ""
            }
            
            return nil
        }

        createButton.target = self
        createButton.releaseAction = "attemptCreate"

        let verticalConfiguration = SAVViewDistributionConfiguration()
        verticalConfiguration.interSpace = 0
        verticalConfiguration.vertical = true
        
        let cardHeight = UIDevice.isShortPhone() ? Sizes.row * 50 : Sizes.row * 60

        view.addSubview(container)
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, cardHeight), forView: container, isRelative: false)
        view.sav_pinView(container, withOptions: .CenterX | .CenterY)
        container.backgroundColor = Colors.color1shade1
        container.layer.cornerRadius = 4.0
        
        view.addSubview(scrollView)
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, cardHeight), forView: scrollView, isRelative: false)
        view.sav_pinView(scrollView, withOptions: .CenterX | .CenterY)

        let topSpacing = UIDevice.isShortPhone() ? Sizes.row * 5 : Sizes.row * 10

        let fieldContainer = UIView.sav_viewWithEvenlyDistributedViews([firstNameField, lastNameField], withConfiguration: verticalConfiguration)
        scrollView.addSubview(fieldContainer)
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: topSpacing)
        scrollView.sav_pinView(fieldContainer, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        scrollView.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 38, forView: fieldContainer, isRelative: false)
        
        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)

        scrollView.addSubview(createButton)
        scrollView.sav_pinView(createButton, withOptions: .CenterX)
        scrollView.sav_pinView(createButton, withOptions: .ToBottom, ofView: fieldContainer, withSpace: Sizes.row * 4)
        scrollView.sav_setSize(buttonSize, forView: createButton, isRelative: false)

        scrollView.addSubview(spinner)
        scrollView.delaysContentTouches = false
        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: createButton, withSpace: 0)
        spinner.hidden = true

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

    func attemptCreate() {
        var attempt = true

        if !firstNameField.validate() {
            attempt = false
        }

        if !lastNameField.validate() {
            attempt = false
        }

        if attempt {
            create()
        } else {
            adjustForView(createButton)
        }
    }

    private func create() {
        createButton.hidden = true
        spinner.startAnimating()
        spinner.hidden = false
        
        if (firstNameField.textField.isFirstResponder()) {
            firstNameField.textField.resignFirstResponder()
        } else if(lastNameField.textField.isFirstResponder()) {
            lastNameField.textField.resignFirstResponder()
        }
        
        adjustForView(nil)

        cancelBlock = Savant.cloud().createCloudUserWithEmail(email, password: password, firstName: firstNameField.text!, lastName: lastNameField.text!, acceptsTermsAndConditions: true) { (success, _, error, isHTTPTransportError) in
            self.cancelBlock = nil
            self.createButton.hidden = false
            self.spinner.stopAnimating()
            self.spinner.hidden = true

            if success {
                self.cancelBlock = Savant.cloud().loginAsCloudUserWithEmail(self.email, password: self.password, completionHandler: { (loginSuccess, _, loginError, loginIsHTTPTransportError) in
                    self.cancelBlock = nil
                    if loginSuccess {
                        RootCoordinator.transitionToState(.HomePicker)
                    } else {
                        let alert = SCUAlertView(error: loginError)
                        alert.show()
                    }
                })

            } else {
                let alert = SCUAlertView(error: error)
                alert.show()
            }
        }
    }

    override func handleBack() {
        coordinator.transitionToState(.SignUpEmail(email: email, password: password))
    }

}
