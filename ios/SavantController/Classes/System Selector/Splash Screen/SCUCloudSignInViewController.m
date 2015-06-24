//
//  SCUCloudSignInViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCloudSignInViewController.h"
#import "SCUMainViewController.h"
#import "SCUAlertView.h"
#import "SCUButton.h"
#import "SCUErrorTextField.h"
#import <SavantControl/SavantControl.h>
#import "OnePasswordExtension.h"

@interface SCUCloudSignInViewController () <UITextFieldDelegate>

@property (nonatomic) NSString *email;
@property (nonatomic) NSString *password;
@property (nonatomic) BOOL autoSignIn;
@property (nonatomic) SCUErrorTextField *emailField;
@property (nonatomic) SCUErrorTextField *passwordField;
@property (nonatomic) SCUButton *signIn;
@property (nonatomic) SCUButton *forgotPassword;
@property (nonatomic) SCUButton *passwordExtension;
@property (nonatomic, copy) SCSCancelBlock signInCancelBlock;
@property (nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation SCUCloudSignInViewController

- (instancetype)initWithEmail:(NSString *)email password:(NSString *)password
{
    self = [super init];

    if (self)
    {
        self.email = email;
        self.password = password;
        self.autoSignIn = YES;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setHidesBackButton:YES animated:NO];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    self.title = NSLocalizedString(@"Sign In", nil);

    self.passwordExtension = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"onepassword-button"]];
    self.passwordExtension.selectedColor = [[SCUColors shared] color01];
    self.passwordExtension.selectedBackgroundColor = [UIColor clearColor];
    self.passwordExtension.target = self;
    self.passwordExtension.releaseAction = @selector(launchPasswordExtensions);

    self.emailField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.returnKeyType = UIReturnKeyNext;
    self.emailField.tag = 0;
    self.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email Address", nil)
                                                                            attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.passwordField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.passwordField.secureTextEntry = YES;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.tag = 1;
    self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil)
                                                                               attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    if (self.email)
    {
        self.emailField.text = self.email;
    }

    if (self.password)
    {
        self.passwordField.text = self.password;
    }

    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable])
    {
        self.passwordField.rightViewMode = UITextFieldViewModeAlways;
        self.passwordField.rightView = self.passwordExtension;
    }

    for (UITextField *field in @[self.emailField, self.passwordField])
    {
        field.delegate = self;
        field.textColor = [[SCUColors shared] color04];
        field.backgroundColor = [[SCUColors shared] color03shade03];
    }

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.separatorBlock = ^UIView *{
        return [UIView sav_viewWithColor:[[SCUColors shared] color03shade05]];
    };
    configuration.separatorSize = [UIScreen screenPixel];
    configuration.vertical = YES;
    configuration.interSpace = 0;
    configuration.fixedHeight = 60;

    UIView *fieldContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.emailField, self.passwordField] withConfiguration:configuration];
    [self.view addSubview:fieldContainer];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsToTop withSpace:20];

    self.signIn = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"SIGN IN", nil)];
    self.signIn.target = self;
    self.signIn.releaseAction = @selector(handleSignIn:);
    self.signIn.roundedCorners = YES;
    self.signIn.color = [[SCUColors shared] color01];
    self.signIn.backgroundColor = [UIColor clearColor];
    self.signIn.borderWidth = [UIScreen screenPixel];
    self.signIn.borderColor = [[SCUColors shared] color03shade04];
    [self.view addSubview:self.signIn];

    if ([UIDevice isPad])
    {
        [self.view sav_setWidth:300 forView:self.signIn isRelative:NO];
    }
    else
    {
        [self.view sav_setWidth:.9 forView:self.signIn isRelative:YES];
    }

    [self.view sav_setHeight:60 forView:self.signIn isRelative:NO];
    [self.view sav_pinView:self.signIn withOptions:SAVViewPinningOptionsCenterX];
    [self.view sav_pinView:self.signIn withOptions:SAVViewPinningOptionsToBottom ofView:fieldContainer withSpace:14];

    self.forgotPassword = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Forgot Your Password?", nil)];
    self.forgotPassword.target = self;
    self.forgotPassword.releaseAction = @selector(resetPassword:);
    self.forgotPassword.color = [[SCUColors shared] color01];
    self.forgotPassword.selectedColor = [self.forgotPassword.color colorWithAlphaComponent:.6];
    self.forgotPassword.backgroundColor = [UIColor clearColor];
    self.forgotPassword.selectedBackgroundColor = [UIColor clearColor];
    self.forgotPassword.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:self.forgotPassword];
    [self.view sav_pinView:self.forgotPassword withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:self.forgotPassword withOptions:SAVViewPinningOptionsToBottom ofView:self.signIn withSpace:14];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    [self.view addGestureRecognizer:tapGesture];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidden = YES;
    [self.view addSubview:self.spinner];
    [self.view sav_pinView:self.spinner withOptions:SAVViewPinningOptionsCenterX ofView:self.signIn withSpace:0];
    [self.view sav_pinView:self.spinner withOptions:SAVViewPinningOptionsCenterY ofView:self.signIn withSpace:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.autoSignIn)
    {
        [self handleSignIn:self.signIn];
    }
    else
    {
        [self.emailField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.signInCancelBlock)
    {
        self.signInCancelBlock();
        self.signInCancelBlock = NULL;
    }
}

- (void)handleSignIn:(SCUButton *)sender
{
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;

    [self endEditing];

    for (SCUErrorTextField *textField in @[self.emailField, self.passwordField])
    {
        [self validateTextField:textField];
    }

    if (self.emailField.errorMessage || self.passwordField.errorMessage)
    {
        return;
    }

    sender.hidden = YES;
    [self.view endEditing:YES];
    self.spinner.hidden = NO;
    [self.spinner startAnimating];

    self.signInCancelBlock = [[SavantControl sharedControl] loginAsCloudUserWithEmail:email password:password completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {

        self.signInCancelBlock = nil;

        if (success)
        {
            sender.title = NSLocalizedString(@"Success", nil);
            sender.target = nil;
            sender.releaseAction = NULL;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[SCUMainViewController sharedInstance] presentSystemSelector:SCUSystemSelectorFromLocationSignIn];
            });
        }
        else
        {
            SCUAlertView *alertView = [[SCUAlertView alloc] initWithError:error];
            [alertView show];
        }

        [self.spinner stopAnimating];
        self.spinner.hidden = YES;
        sender.hidden = NO;
    }];
}

- (void)resetPassword:(SCUButton *)sender
{
    [self endEditing];

    NSString *email = self.emailField.text;

    SCUAlertView *alertView = nil;

    if ([email length])
    {
        alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Password?", nil)
                                                message:NSLocalizedString(@"Are you sure you would like to reset your password? You will receive an email with further instructions.", nil)
                                           buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Reset", nil)]];

        alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

        alertView.callback = ^(NSUInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [[SavantControl sharedControl] resetPasswordForEmail:email completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                    //-------------------------------------------------------------------
                    // CBP TODO: Handle this
                    //-------------------------------------------------------------------
                }];
            }
        };
    }
    else
    {
        alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                message:NSLocalizedString(@"Please enter your email to reset your password.", nil)
                                           buttonTitles:@[NSLocalizedString(@"OK", nil)]];
    }

    [alertView show];
}

- (void)endEditing
{
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    SCUErrorTextField *errorField = (SCUErrorTextField *)textField;
    [errorField restore];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        [textField resignFirstResponder];
        [self handleSignIn:self.signIn];
        return YES;
    }
    else
    {
        NSInteger nextTag = textField.tag + 1;

        UIResponder *nextResponder = [self.view viewWithTag:nextTag];

        if (nextResponder)
        {
            [nextResponder becomeFirstResponder];
        }
        else
        {
            [textField resignFirstResponder];
        }

        return NO;
    }
}

- (void)validateTextField:(SCUErrorTextField *)textField
{
    NSString *errorMessage = nil;
    NSString *text = textField.text;

    if (textField == self.emailField)
    {
        if (![text length])
        {
            errorMessage = NSLocalizedString(@"Enter your email", nil);
        }
        else
        {
            if (![text sav_isValidEmail])
            {
                errorMessage = NSLocalizedString(@"Enter a valid email", nil);
            }
        }
    }
    else if (textField == self.passwordField)
    {
        if (![text length])
        {
            errorMessage = NSLocalizedString(@"Enter your password", nil);
        }
    }

    if (errorMessage)
    {
        textField.errorMessage = errorMessage;
    }
}

#pragma mark - Password Extension

- (void)launchPasswordExtensions
{
    SAVWeakSelf;
    [[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://www.savant.com"
                                                forViewController:self
                                                           sender:self.passwordExtension
                                                       completion:^(NSDictionary *loginDict, NSError *error) {
                                                           SAVStrongWeakSelf;
                                                           if (loginDict)
                                                           {
                                                               sSelf.emailField.text = loginDict[AppExtensionUsernameKey];
                                                               sSelf.passwordField.text = loginDict[AppExtensionPasswordKey];

                                                               if ([sSelf.emailField.text length] && [sSelf.passwordField.text length])
                                                               {
                                                                   [sSelf handleSignIn:self.signIn];
                                                               }
                                                           }
                                                       }];
}

@end
