//
//  SCUChangePasswordViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUChangePasswordViewController.h"
#import "SCUErrorTextField.h"
#import "SCUButton.h"
#import "SCUAlertView.h"

#import "OnePasswordExtension.h"

@interface SCUChangePasswordViewController () <UITextFieldDelegate>

@property (nonatomic) SAVCloudUser *user;
@property (nonatomic) SCUErrorTextField *oldPasswordField;
@property (nonatomic) SCUErrorTextField *passwordField;
@property (nonatomic) SCUErrorTextField *passwordConfirmField;
@property (nonatomic) SCUButton *button;
@property (nonatomic) SCUButton *passwordExtension;

@end

@implementation SCUChangePasswordViewController

- (instancetype)initWithCloudUser:(SAVCloudUser *)user
{
    self = [super init];

    if (self)
    {
        self.user = user;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    self.title = NSLocalizedString(@"Change Password", nil);

    self.passwordExtension = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"onepassword-button"]];
    self.passwordExtension.selectedColor = [[SCUColors shared] color01];
    self.passwordExtension.selectedBackgroundColor = [UIColor clearColor];
    self.passwordExtension.target = self;
    self.passwordExtension.releaseAction = @selector(launchPasswordExtensions);

    self.oldPasswordField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.oldPasswordField.tag = 0;
    self.oldPasswordField.returnKeyType = UIReturnKeyNext;
    self.oldPasswordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Current Password", nil)
                                                                                  attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.passwordField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.passwordField.tag = 1;
    self.passwordField.returnKeyType = UIReturnKeyNext;
    self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"New Password", nil)
                                                                               attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.passwordConfirmField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.passwordConfirmField.tag = 2;
    self.passwordConfirmField.returnKeyType = UIReturnKeyDone;
    self.passwordConfirmField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Confirm New Password", nil)
                                                                                      attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable])
    {
        self.passwordField.rightViewMode = UITextFieldViewModeAlways;
        self.passwordField.rightView = self.passwordExtension;
    }

    for (SCUErrorTextField *field in @[self.oldPasswordField, self.passwordField, self.passwordConfirmField])
    {
        field.delegate = self;
        field.secureTextEntry = YES;
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

    UIView *fieldContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.oldPasswordField, self.passwordField, self.passwordConfirmField]
                                                      withConfiguration:configuration];

    [self.view addSubview:fieldContainer];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsToTop withSpace:20];

    self.button = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"CHANGE PASSWORD", nil)];
    self.button.target = self;
    self.button.releaseAction = @selector(handleChangePassword);
    self.button.roundedCorners = YES;
    self.button.color = [[SCUColors shared] color01];
    self.button.backgroundColor = [UIColor clearColor];
    self.button.borderWidth = [UIScreen screenPixel];
    self.button.borderColor = [[SCUColors shared] color03shade04];
    [self.view addSubview:self.button];

    [self.view sav_setHeight:60 forView:self.button isRelative:NO];
    [self.view sav_pinView:self.button withOptions:SAVViewPinningOptionsCenterX];
    [self.view sav_pinView:self.button withOptions:SAVViewPinningOptionsToBottom ofView:fieldContainer withSpace:14];

    if ([UIDevice isPad])
    {
        [self.view sav_setWidth:300 forView:self.button isRelative:NO];
    }
    else
    {
        [self.view sav_setWidth:.9 forView:self.button isRelative:YES];
    }
}

- (void)handleChangePassword
{
    [self.view endEditing:YES];

    NSString *originalPassword = self.passwordField.text;

    for (SCUErrorTextField *textField in @[self.oldPasswordField, self.passwordField, self.passwordConfirmField])
    {
        [self validateTextField:textField];
    }

    if (self.passwordField.errorMessage && [originalPassword length])
    {
        [[[SCUAlertView alloc] initInvalidPasswordAlert] show];
    }

    for (SCUErrorTextField *textField in @[self.oldPasswordField, self.passwordField, self.passwordConfirmField])
    {
        if (textField.errorMessage)
        {
            return;
        }
    }

    NSString *userID = self.user.identifier;
    NSString *oldPassword = self.oldPasswordField.text;
    NSString *newPassword = self.passwordField.text;

    SAVWeakSelf;
    [[SavantControl sharedControl] changePasswordWithUserID:userID oldPassword:oldPassword newPassword:newPassword completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        if (success)
        {
            [wSelf.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            NSString *message = nil;

            if (isHTTPTransportError)
            {
                message = NSLocalizedString(@"Could not communicate with Savant.", nil);
            }
            else
            {
                message = NSLocalizedString(@"Your password could not be changed. Make sure you entered your current password correctly.", nil);
            }

            SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                  message:message
                                                             buttonTitles:@[NSLocalizedString(@"OK", nil)]];

            [alertView show];
        }
    }];
}

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
        [self handleChangePassword];
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

    if (textField == self.oldPasswordField)
    {
        if (![text length])
        {
            errorMessage = NSLocalizedString(@"Enter your current password", nil);
        }
    }
    else if (textField == self.passwordField)
    {
        if (![text sav_isValidPassword])
        {
            errorMessage = NSLocalizedString(@"Enter a valid password", nil);
        }
    }
    else if (textField == self.passwordConfirmField)
    {
        if ([self.passwordField.text length] && ![text isEqualToString:self.passwordField.text])
        {
            errorMessage = NSLocalizedString(@"New password must match", nil);
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
    NSDictionary *newLoginDetails = @{
                                      AppExtensionTitleKey: @"Savant",
                                      AppExtensionUsernameKey: self.user.email ? : @"",
                                      AppExtensionPasswordKey: self.passwordField.text ? : @"",
                                      AppExtensionOldPasswordKey: self.oldPasswordField.text ? : @"",
                                      AppExtensionNotesKey: @"Saved with the Savant app",
                                      AppExtensionSectionTitleKey: @"Savant Cloud",
                                      AppExtensionFieldsKey: @{
                                              @"First Name" : self.user.firstName ? : @"",
                                              @"Last Name" : self.user.lastName ? : @""
                                              }
                                      };

    // Password generation options are optional, but are very handy in case you have strict rules about password lengths
    NSDictionary *passwordGenerationOptions = @{
                                                AppExtensionGeneratedPasswordMinLengthKey: @(8),
                                                AppExtensionGeneratedPasswordMaxLengthKey: @(50)
                                                };

    SAVWeakSelf;
    [[OnePasswordExtension sharedExtension] changePasswordForLoginForURLString:@"http://www.savant.com"
                                                                  loginDetails:newLoginDetails
                                                     passwordGenerationOptions:passwordGenerationOptions
                                                             forViewController:self
                                                                        sender:self.passwordExtension
                                                                    completion:^(NSDictionary *loginDict, NSError *error) {
                                                                        SAVStrongWeakSelf;
                                                                        if (loginDict)
                                                                        {
                                                                            sSelf.passwordField.text = loginDict[AppExtensionPasswordKey] ? : @"";
                                                                            sSelf.passwordConfirmField.text = loginDict[AppExtensionPasswordKey] ? : @"";
                                                                            sSelf.oldPasswordField.text = loginDict[AppExtensionOldPasswordKey] ? : @"";
                                                                        }
                                                                    }];
}

@end
