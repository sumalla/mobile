//
//  SignUpEmailPage.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class SignUpEmailPage: LandingPageContentBase {

    let emailField = ErrorTextField(style: .Dark)
    let emailConfirmationField = ErrorTextField(style: .Dark)
    let passwordField = ErrorTextField(style: .Dark)
    let eulaLabel = TTTAttributedLabel()
    let nextButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Next", comment: ""))
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    let container = UIView(frame: CGRectZero)
    let scrollView = UIScrollView(frame: CGRectZero)
    var fieldContainer = UIView(frame: CGRectZero)
    var keyboardHeight: CGFloat = 0
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)

        container.backgroundColor = Colors.color1shade1
        container.layer.cornerRadius = 4.0
        
        scrollView.scrollEnabled = false
        
        emailField.placeholder = NSLocalizedString("email", comment: "")
        emailConfirmationField.placeholder = NSLocalizedString("confirm email", comment: "")
        passwordField.placeholder = NSLocalizedString("password", comment: "")

        for field in [emailField, emailConfirmationField] {
            field.textField.returnKeyType = .Next
            field.textField.keyboardType = .EmailAddress
            field.textField.autocorrectionType = .No
            field.textField.autocapitalizationType = .None
        }

        passwordField.textField.secureTextEntry = true
        passwordField.textField.returnKeyType = .Done
        passwordField.clearErrorOnTextEditingStart = false

        eulaLabel.textAlignment = .Center
        eulaLabel.numberOfLines = 0
        eulaLabel.delegate = self
        let eulaText = NSLocalizedString("By selecting “Next”, you are agreeing to Savant's user agreement and privacy policy", comment: "")
        eulaLabel.setText(NSAttributedString(string: eulaText, attributes: [NSForegroundColorAttributeName: Colors.color3shade2, NSFontAttributeName: Fonts.caption1]))

        eulaLabel.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        eulaLabel.activeLinkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue, NSForegroundColorAttributeName: Colors.color3shade1]

        nextButton.target = self
        nextButton.releaseAction = "attemptNext"

        spinner.hidden = true

        let userAgreementRange = (eulaText as NSString).rangeOfString(NSLocalizedString("user agreement", comment: ""))
        eulaLabel.addLinkToURL(NSURL(string: "https://www.savant.com/eula"), withRange: userAgreementRange)

        let privacyPolicyRange = (eulaText as NSString).rangeOfString(NSLocalizedString("privacy policy", comment: ""))
        eulaLabel.addLinkToURL(NSURL(string: "https://www.savant.com/privacy-policy"), withRange: privacyPolicyRange)

        let verticalConfiguration = SAVViewDistributionConfiguration()
        verticalConfiguration.interSpace = 0
        verticalConfiguration.vertical = true
        
        fieldContainer = UIView.sav_viewWithEvenlyDistributedViews([emailField, emailConfirmationField, passwordField], withConfiguration: verticalConfiguration)

        view.addSubview(container)
        view.addSubview(scrollView)

        view.sav_pinView(container, withOptions: .CenterX)
        
        scrollView.addSubview(eulaLabel)
        scrollView.addSubview(fieldContainer)
        scrollView.addSubview(nextButton)
        scrollView.addSubview(spinner)
        
        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)
        scrollView.sav_setSize(buttonSize, forView: nextButton, isRelative: false)
        
        scrollView.sav_setWidth(0.8, forView: fieldContainer, isRelative: true)
        scrollView.sav_pinView(fieldContainer, withOptions: .CenterX)
        
        scrollView.sav_setWidth(0.8, forView: eulaLabel, isRelative: true)
        scrollView.sav_pinView(eulaLabel, withOptions: .CenterX)
        
        scrollView.sav_pinView(nextButton, withOptions: .CenterX)
        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: nextButton, withSpace: 0)
        
        setupConstraints()
        setupHandlers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = container.frame
        scrollView.contentSize = scrollView.frame.size
    }
    
    override func phoneConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 46, Sizes.row * 56), forView: container, isRelative: false)
        view.sav_pinView(container, withOptions: .ToTop, withSpace: Sizes.row * 12)
        
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 5)
        scrollView.sav_pinView(nextButton, withOptions: .ToBottom, ofView: eulaLabel, withSpace: Sizes.row * 3)
        scrollView.sav_pinView(eulaLabel, withOptions: .ToBottom, ofView: fieldContainer, withSpace: Sizes.row * 1)
    }
    
    override func universalPadConstraints() {
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 9)
        scrollView.sav_pinView(nextButton, withOptions: .ToTop, withSpace: Sizes.row * 46)
        scrollView.sav_pinView(eulaLabel, withOptions: .ToTop, withSpace: Sizes.row * 37)
        
        view.sav_pinView(container, withOptions: .CenterY)
    }

    override func padPortraitConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32, Sizes.row * 57), forView: container, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 30, Sizes.row * 57), forView: container, isRelative: false)
    }
    
    func setupHandlers() {
        
        emailField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(emailField)
            })
        }
        
        emailConfirmationField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(passwordField)
            })
        }
        
        passwordField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(nextButton)
            })
        }
        
        emailField.returnHandler = { [weak self] in
            self?.emailConfirmationField.textField.becomeFirstResponder()
        }
        
        emailConfirmationField.returnHandler = { [weak self] in
            self?.passwordField.textField.becomeFirstResponder()
        }
        
        passwordField.returnHandler = { [weak self] in
            self?.attemptNext()
        }
        
        emailField.validationHandler = {
            if $0.isEmpty {
                return ""
            } else if !$0.sav_isValidEmail() {
                return NSLocalizedString("Enter a valid email address", comment: "").uppercaseString
            }
            
            return nil
        }
        
        emailConfirmationField.validationHandler = { [unowned emailField] in
            if $0 != emailField.text {
                return NSLocalizedString("Email addresses do not match", comment: "").uppercaseString
            } else if $0.isEmpty {
                return ""
            }
            
            return nil
        }
        
        passwordField.validationHandler = {
            if !$0.sav_isValidPassword() {
                return NSLocalizedString("Requires 8 characters minimum.\nInclude 1 number, 1 capital & 1 lower case.", comment: "")
            }
            
            return nil
        }

        eulaLabel.textAlignment = .Center
        eulaLabel.numberOfLines = 0
        eulaLabel.delegate = self
        let eulaText = NSLocalizedString("By selecting “Next”, you are agreeing to Savant's user agreement and privacy policy", comment: "")
        eulaLabel.setText(NSAttributedString(string: eulaText, attributes: [NSForegroundColorAttributeName: Colors.color3shade2, NSFontAttributeName: Fonts.caption1]))

        eulaLabel.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        eulaLabel.activeLinkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue, NSForegroundColorAttributeName: Colors.color3shade1]

        nextButton.target = self
        nextButton.releaseAction = "attemptNext"

        let userAgreementRange = (eulaText as NSString).rangeOfString(NSLocalizedString("user agreement", comment: ""))
        eulaLabel.addLinkToURL(NSURL(string: "https://www.savant.com/eula"), withRange: userAgreementRange)

        let privacyPolicyRange = (eulaText as NSString).rangeOfString(NSLocalizedString("privacy policy", comment: ""))
        eulaLabel.addLinkToURL(NSURL(string: "https://www.savant.com/privacy-policy"), withRange: privacyPolicyRange)

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
        let fieldContainer = UIView.sav_viewWithEvenlyDistributedViews([emailField, emailConfirmationField, passwordField], withConfiguration: verticalConfiguration)
        scrollView.addSubview(fieldContainer)
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: topSpacing)
        scrollView.sav_pinView(fieldContainer, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        scrollView.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 38, forView: fieldContainer, isRelative: false)
        
        scrollView.addSubview(eulaLabel)
        scrollView.sav_pinView(eulaLabel, withOptions: .ToBottom, ofView: fieldContainer, withSpace: Sizes.row * 0.5)
        scrollView.sav_pinView(eulaLabel, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 5)
        scrollView.sav_setWidth(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 38, forView: eulaLabel, isRelative: false)

        scrollView.addSubview(nextButton)
        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)

        scrollView.sav_pinView(nextButton, withOptions: .CenterX)
        scrollView.sav_pinView(nextButton, withOptions: .ToBottom, ofView: eulaLabel, withSpace: Sizes.row * 3)
        scrollView.sav_setSize(buttonSize, forView: nextButton, isRelative: false)

        scrollView.addSubview(spinner)
        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: nextButton, withSpace: 0)
        scrollView.delaysContentTouches = false
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
        keyboardHeight = 0
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
    
    func attemptNext() {
        var attempt = true

        if !emailField.validate() {
            attempt = false
        }

        if !emailConfirmationField.validate() {
            attempt = false
        }

        if !passwordField.validate() {
            attempt = false
        }

        if attempt {
            next()
        } else{
            view.layoutIfNeeded()
            adjustForView(nextButton)
        }
    }
    
    func resignAllResponders() {
        if (emailField.textField.isFirstResponder()) {
            emailField.textField.resignFirstResponder()
        } else if(emailConfirmationField.textField.isFirstResponder()) {
            emailConfirmationField.textField.resignFirstResponder()
        } else if (passwordField.textField.isFirstResponder()) {
            passwordField.textField.resignFirstResponder()
        }
    }

    func next() {
        nextButton.hidden = true
        spinner.hidden = false
        spinner.startAnimating()
        
        resignAllResponders()
        
        adjustForView(nil)

        cancelBlock = Savant.cloud().checkIfEmailExists(emailField.text!, completionHandler: { (exists) in
            self.cancelBlock = nil
            self.spinner.stopAnimating()
            self.spinner.hidden = true
            self.nextButton.hidden = false
            
            if exists {
                let alert = SCUAlertView(title: NSLocalizedString("Sign In", comment: ""),
                    message: String(format: NSLocalizedString("The account %@ has already been created. Would you like to sign in?", comment: ""), self.emailField.text!),
                    buttonTitles: [NSLocalizedString("Cancel", comment: ""), NSLocalizedString("Sign In", comment: "")])

                alert.primaryButtons = NSIndexSet(index: 1)
                alert.callback = {
                    if $0 == 1 {
                        self.coordinator.transitionToState(.SignIn(email: self.emailField.text, password: self.passwordField.text))
                    }
                }

                alert.show()

            } else {
                self.coordinator.transitionToState(.SignUpUserProfile(email: self.emailField.text!, password: self.passwordField.text!))
            }
        })

    }

    override func handleBack() {
        coordinator.transitionToState(.Landing)
    }

}

extension SignUpEmailPage: TTTAttributedLabelDelegate {

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

}
