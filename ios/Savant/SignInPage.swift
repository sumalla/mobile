//
//  SignInPage.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/25/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class SignInPage: LandingPageContentBase, UIViewControllerTransitioningDelegate {

    let emailField = ErrorTextField(style: .Dark)
    let passwordField = ErrorTextField(style: .Dark)
    let signInButton = SCUButton(style: .StandardPillDark, title: Strings.signIn)
    let forgotButton = SCUButton(style: .Dark, attributedTitle: NSAttributedString.sav_underlinedAttributedStringWithString(Strings.iForgotMyPassword))
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    let container = UIView(frame: CGRectZero)
    let scrollView = UIScrollView(frame: CGRectZero)
    var fieldContainer = UIView(frame: CGRectZero)
    var keyboardHeight: CGFloat = 216

    let email: String?
    let password: String?

    init(coordinator c: CoordinatorReference<SignInState>, email e: String?, password p: String?) {
        email = e
        password = p
        super.init(coordinator: c)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)

        spinner.tintColor = Colors.color3shade1
        
        view.addSubview(container)
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 48, Sizes.row * 50), forView: container, isRelative: false)
        view.sav_pinView(container, withOptions: .CenterX | .CenterY)
        
        container.backgroundColor = Colors.color1shade1
        container.layer.cornerRadius = 4.0
        
        scrollView.scrollEnabled = false

        spinner.hidden = true
        
        emailField.textField.returnKeyType = .Next
        emailField.textField.keyboardType = .EmailAddress
        emailField.textField.autocorrectionType = .No
        emailField.textField.autocapitalizationType = .None

        passwordField.textField.secureTextEntry = true
        passwordField.textField.returnKeyType = .Done


        emailField.placeholder = Strings.email.lowercaseString
        passwordField.placeholder = Strings.password.lowercaseString

        emailField.validationHandler = {
            if $0.isEmpty {
                return ""
            } else if !$0.sav_isValidEmail() {
                return Strings.enterValidEmailAddress.uppercaseString
            }

            return nil
        }

        passwordField.validationHandler = {
            if $0.isEmpty {
                return ""
            }

            return nil
        }


        forgotButton.titleLabel?.font = Fonts.caption1

        signInButton.target = self
        signInButton.releaseAction = "attemptSignIn"

        forgotButton.target = self
        forgotButton.releaseAction = "attemptForgotPassword"
        
        if let email = email, password = password {
            emailField.text = email
            passwordField.text = password
        }
        
        let verticalConfiguration = SAVViewDistributionConfiguration()
        verticalConfiguration.interSpace = 0
        verticalConfiguration.vertical = true
        
        fieldContainer = UIView.sav_viewWithEvenlyDistributedViews([emailField, passwordField], withConfiguration: verticalConfiguration)

        view.addSubview(container)
        view.addSubview(scrollView)
        
        view.sav_pinView(container, withOptions: .CenterX)
        
        scrollView.addSubview(signInButton)
        scrollView.addSubview(spinner)
        scrollView.addSubview(forgotButton)
        scrollView.addSubview(fieldContainer)

        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 10)
        scrollView.sav_pinView(fieldContainer, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        scrollView.sav_setWidth(0.75, forView: fieldContainer, isRelative: true)

        let buttonSize = CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)

        scrollView.sav_pinView(signInButton, withOptions: .CenterX)
        scrollView.sav_pinView(signInButton, withOptions: .ToBottom, ofView: fieldContainer, withSpace: Sizes.row * 4)
        scrollView.sav_setSize(buttonSize, forView: signInButton, isRelative: false)
        scrollView.delaysContentTouches = false

        scrollView.sav_pinView(spinner, withOptions: .CenterX | .CenterY, ofView: signInButton, withSpace: 0)
        scrollView.sav_pinView(signInButton, withOptions: .CenterX)
        scrollView.sav_pinView(forgotButton, withOptions: .CenterX)
        scrollView.sav_pinView(forgotButton, withOptions: .ToBottom, ofView: signInButton, withSpace: Sizes.row * 4)

        scrollView.sav_setWidth(0.8, forView: fieldContainer, isRelative: true)
        scrollView.sav_pinView(fieldContainer, withOptions: .CenterX)

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
        
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 8)
        scrollView.sav_pinView(signInButton, withOptions: .ToTop, withSpace: Sizes.row * 29)
        scrollView.sav_pinView(forgotButton, withOptions: .ToTop, withSpace: Sizes.row * 39)
    }
    
    override func universalPadConstraints() {
        scrollView.sav_pinView(fieldContainer, withOptions: .ToTop, withSpace: Sizes.row * 8)
        scrollView.sav_pinView(signInButton, withOptions: .ToTop, withSpace: Sizes.row * 29)
        scrollView.sav_pinView(forgotButton, withOptions: .ToTop, withSpace: Sizes.row * 39)
        
        view.sav_pinView(container, withOptions: .CenterY)
    }

    override func padPortraitConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 32, Sizes.row * 58), forView: container, isRelative: false)
    }
    
    override func padLandscapeConstraints() {
        view.sav_setSize(CGSizeMake(Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 28, Sizes.row * 58), forView: container, isRelative: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let email = email, password = password {
            attemptSignIn()
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let height = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().size.height {
                keyboardHeight = height
            }
        }
    }
    
    func setupHandlers() {
        
        emailField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(emailField)
            })
            
        }
        
        emailField.returnHandler = { [weak self] in
            self?.passwordField.textField.becomeFirstResponder()
        }
        
        passwordField.beginHandler = { [weak self] in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.adjustForView(forgotButton)
            })
        }
        
        passwordField.returnHandler = { [weak self] in
            self?.attemptSignIn()
        }
        
        emailField.validationHandler = {
            if $0.isEmpty {
                return ""
            } else if !$0.sav_isValidEmail() {
                return NSLocalizedString("Enter a valid email address", comment: "").uppercaseString
            }
            
            return nil
        }
        
        passwordField.validationHandler = {
            if $0.isEmpty {
                return ""
            }
            
            return nil
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
        var attempt = true

        if !emailField.validate() {
            attempt = false
        }

        if !passwordField.validate() {
            attempt = false
        }

        if attempt {
            clearErrors()
            signIn()
        }
    }

    private func signIn() {
        signInButton.hidden = true
        spinner.hidden = false
        spinner.startAnimating()

        cancelBlock = Savant.cloud().loginAsCloudUserWithEmail(emailField.text!, password: passwordField.text!) { (success, _, error, isHTTPTransportError) -> Void in
            self.cancelBlock = nil
            
            if success {
                RootCoordinator.transitionToState(.HomePicker)
            } else {
                if isHTTPTransportError {
                    let alert = SCUAlertView(
                        title: Strings.connectionError,
                        message: Strings.couldNotCommunicateWithSavant,
                        buttonTitles: [Strings.ok])

                    alert.show()
                } else if let error = error {
                    switch error.code {
                    case SCSResponseError.InvalidPassword.rawValue:
                        self.passwordField.errorText = Strings.invalidPassword.uppercaseString
                    case SCSResponseError.UnknownEmail.rawValue:
                        self.emailField.errorText = Strings.emailAddressNotFound.uppercaseString
                    default:
                        let alert = SCUAlertView(error: error)
                        alert.show()
                    }
                }

                self.spinner.stopAnimating()
                self.spinner.hidden = true
                self.signInButton.hidden = false
            }
        }
    }

    func attemptForgotPassword() {
        var attempt = emailField.validate()
        passwordField.text = nil
        passwordField.errorText = nil

        if attempt {
            clearErrors()
            forgotPassword()
        }
    }

    private func forgotPassword() {
        let alert = SCUAlertView(
            title: Strings.forgotYourPasswordQuestionMark,
            message: Strings.forgotYourPasswordInstructions,
            buttonTitles: [Strings.cancel, Strings.reset])

        alert.primaryButtons = NSIndexSet(index: 1)

        alert.callback = {
            if $0 == 1 {
                Savant.cloud().resetPasswordForEmail(self.emailField.text!) { _ in

                }
            }
        }

        alert.show()
    }

    private func clearErrors() {
        emailField.errorText = nil
        passwordField.errorText = nil
        self.view.endEditing(true)
    }

    override func handleBack() {
        coordinator.transitionToState(.Landing)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentationAnimator = SlideAnimator()
        return presentationAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let dismissalAnimator = SlideAnimator()
        return dismissalAnimator
    }
}
