//
//  SCUCloudSignUpViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCloudSignUpViewController.h"
#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>
#import "SCUCloudSignUpSuccessViewController.h"
#import "SCUAlertView.h"
#import "SCUErrorTextField.h"
#import "SCUButton.h"
#import "SCUCloudSignInViewController.h"

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "OnePasswordExtension.h"

typedef NS_ENUM(NSInteger, SCUSignUpTextFieldTag)
{
    SCUSignUpTextFieldTagFirstName = 0,
    SCUSignUpTextFieldTagLastName = 1,
    SCUSignUpTextFieldTagEmail = 2,
    SCUSignUpTextFieldTagPassword = 3
};

@interface SCUCloudSignUpViewController () <UITextFieldDelegate, TTTAttributedLabelDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) SCUErrorTextField *firstNameField;
@property (nonatomic) SCUErrorTextField *lastNameField;
@property (nonatomic) SCUErrorTextField *emailField;
@property (nonatomic) SCUErrorTextField *passwordField;
@property (nonatomic) SCUButton *signUp;
@property (nonatomic) SCUButton *passwordExtension;

@property (nonatomic) CGFloat yOffset;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) id<NSObject> keyboardShowObserver;
@property (nonatomic) id<NSObject> keyboardHideObserver;
@property (nonatomic, copy) SCSCancelBlock signUpCancelBlock;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) TTTAttributedLabel *marketingLabel;

@end

@implementation SCUCloudSignUpViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardShowObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardHideObserver];
}

- (void)loadView
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self setScrollViewSize];
    self.view = self.scrollView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setHidesBackButton:YES animated:NO];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    self.title = NSLocalizedString(@"Sign Up", nil);
    self.scrollView.scrollEnabled = NO;

    self.passwordExtension = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"onepassword-button"]];
    self.passwordExtension.selectedColor = [[SCUColors shared] color01];
    self.passwordExtension.selectedBackgroundColor = [UIColor clearColor];
    self.passwordExtension.target = self;
    self.passwordExtension.releaseAction = @selector(launchPasswordExtensions);

    self.firstNameField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.firstNameField.tag = SCUSignUpTextFieldTagFirstName;
    self.firstNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.firstNameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.firstNameField.returnKeyType = UIReturnKeyNext;
    self.firstNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.firstNameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"First Name", nil)
                                                                                attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.lastNameField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.lastNameField.tag = SCUSignUpTextFieldTagLastName;
    self.lastNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.lastNameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.lastNameField.returnKeyType = UIReturnKeyNext;
    self.lastNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.lastNameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Last Name", nil)
                                                                                attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.emailField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.emailField.tag = SCUSignUpTextFieldTagEmail;
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.returnKeyType = UIReturnKeyNext;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email Address", nil)
                                                                                attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    self.passwordField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    self.passwordField.tag = SCUSignUpTextFieldTagPassword;
    self.passwordField.secureTextEntry = YES;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil)
                                                                                attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];

    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable])
    {
        self.passwordField.rightViewMode = UITextFieldViewModeAlways;
        self.passwordField.rightView = self.passwordExtension;
    }

    for (UITextField *field in @[self.firstNameField, self.lastNameField, self.emailField, self.passwordField])
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

    UIView *fieldContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.firstNameField, self.lastNameField, self.emailField, self.passwordField]
                                                      withConfiguration:configuration];

    [self.view addSubview:fieldContainer];
    [self.view sav_setWidth:1 forView:fieldContainer isRelative:YES];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsToTop withSpace:20];
    [self.view sav_pinView:fieldContainer withOptions:SAVViewPinningOptionsToLeft];

    self.signUp = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"SIGN UP", nil)];
    self.signUp.target = self;
    self.signUp.releaseAction = @selector(handleCreateAccount:);
    self.signUp.roundedCorners = YES;
    self.signUp.color = [[SCUColors shared] color01];
    self.signUp.backgroundColor = [UIColor clearColor];
    self.signUp.borderWidth = [UIScreen screenPixel];
    self.signUp.borderColor = [[SCUColors shared] color03shade04];
    [self.view addSubview:self.signUp];

    if ([UIDevice isPad])
    {
        [self.view sav_setWidth:300 forView:self.signUp isRelative:NO];
    }
    else
    {
        [self.view sav_setWidth:.9 forView:self.signUp isRelative:YES];
    }

    [self.view sav_setHeight:60 forView:self.signUp isRelative:NO];
    [self.view sav_pinView:self.signUp withOptions:SAVViewPinningOptionsCenterX];
    [self.view sav_pinView:self.signUp withOptions:SAVViewPinningOptionsToBottom ofView:fieldContainer withSpace:14];

    SAVWeakSelf;
    self.keyboardShowObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        CGRect keyboardFrame = [((NSValue *)(note.userInfo[UIKeyboardFrameEndUserInfoKey])) CGRectValue];
        wSelf.keyboardHeight = CGRectGetHeight(keyboardFrame);
    }];

    self.keyboardHideObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        CGRect frame = wSelf.view.frame;
        frame.origin.y = wSelf.yOffset;

        [UIView animateWithDuration:.2 animations:^{
            wSelf.view.frame = frame;
        }];
    }];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidden = YES;
    [self.view addSubview:self.spinner];
    [self.view sav_pinView:self.spinner withOptions:SAVViewPinningOptionsCenterX ofView:self.signUp withSpace:0];
    [self.view sav_pinView:self.spinner withOptions:SAVViewPinningOptionsCenterY ofView:self.signUp withSpace:0];

    self.marketingLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.marketingLabel.textAlignment = NSTextAlignmentCenter;
    self.marketingLabel.numberOfLines = 0;
    self.marketingLabel.delegate = self;
    [self.view addSubview:self.marketingLabel];

    NSString *text = NSLocalizedString(@"By selecting SIGN UP, you agree to Savant's User Agreement and Privacy Policy", nil);

    [self.marketingLabel setText:[[NSAttributedString alloc] initWithString:text
                                                                 attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04],
                                                                              NSFontAttributeName: [UIFont systemFontOfSize:15]}]];

    self.marketingLabel.linkAttributes = @{NSForegroundColorAttributeName: [[SCUColors shared] color01]};
    self.marketingLabel.activeLinkAttributes = @{NSForegroundColorAttributeName: [[[SCUColors shared] color01] colorWithAlphaComponent:0.7]};

    NSRange userAgreementRange = [text rangeOfString:NSLocalizedString(@"User Agreement", nil)];
    [self.marketingLabel addLinkToURL:[NSURL URLWithString:@"https://www.savant.com/eula"] withRange:userAgreementRange];

    NSRange privacyPolicyRange = [text rangeOfString:NSLocalizedString(@"Privacy Policy", nil)];
    [self.marketingLabel addLinkToURL:[NSURL URLWithString:@"https://www.savant.com/privacy-policy"] withRange:privacyPolicyRange];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.yOffset = CGRectGetMinY(self.view.frame);
    [self.firstNameField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardShowObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardHideObserver];

    if (self.signUpCancelBlock)
    {
        self.signUpCancelBlock();
        self.signUpCancelBlock = NULL;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat width = CGRectGetWidth(self.view.bounds) - 16;
    CGFloat y = CGRectGetMaxY(self.signUp.frame) + 14;
    CGRect rect = [self.marketingLabel.attributedText boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    self.marketingLabel.frame = CGRectMake(8, y, width, CGRectGetHeight(rect));
}

- (void)handleCreateAccount:(SCUButton *)sender
{
    [self.view endEditing:YES];

    NSString *originalPassword = self.passwordField.text;

    for (SCUErrorTextField *textField in @[self.firstNameField, self.lastNameField, self.emailField, self.passwordField])
    {
        [self validateTextField:textField];
    }

    if (self.passwordField.errorMessage && [originalPassword length])
    {
        [[[SCUAlertView alloc] initInvalidPasswordAlert] show];
    }

    if (self.firstNameField.errorMessage || self.lastNameField.errorMessage || self.emailField.errorMessage || self.passwordField.errorMessage)
    {
        return;
    }

    sender.hidden = YES;
    [self.view endEditing:YES];
    self.spinner.hidden = NO;
    [self.spinner startAnimating];

    NSString *firstName = self.firstNameField.text;
    NSString *lastName = self.lastNameField.text;
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;

    self.signUpCancelBlock = [[SavantControl sharedControl] createCloudUserWithEmail:email password:password firstName:firstName lastName:lastName acceptsTermsAndConditions:YES completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {

        if (success)
        {
            sender.title = NSLocalizedString(@"Success", nil);
            sender.target = nil;
            sender.releaseAction = NULL;

            SCUCloudSignUpSuccessViewController *successViewController = [[SCUCloudSignUpSuccessViewController alloc] initWithEmail:email];
            [self.navigationController pushViewController:successViewController animated:YES];
        }
        else
        {
            if (error.code == SCSResponseErrorEmailExists)
            {
                SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In", nil)
                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"The account %@ has already been created. Would you like to sign in?", nil), self.emailField.text]
                                                                 buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Sign In", nil)]];

                alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

                alertView.callback = ^(NSUInteger buttonIndex) {
                    if (buttonIndex == 1)
                    {
                        SCUCloudSignInViewController *signIn = [[SCUCloudSignInViewController alloc] initWithEmail:email password:password];
                        [self.navigationController pushViewController:signIn animated:YES];
                        signIn.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
                    }
                };

                [alertView show];
            }
            else
            {
                SCUAlertView *alertView = [[SCUAlertView alloc] initWithError:error];
                [alertView show];
            }
        }

        [self.spinner stopAnimating];
        self.spinner.hidden = YES;
        sender.hidden = NO;
    }];
}

- (void)handleTap
{
    [self.view endEditing:YES];
    [self scrollToTop];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    SCUErrorTextField *errorTextField = (SCUErrorTextField *)textField;
    [errorTextField restore];

    self.scrollView.scrollEnabled = YES;

    dispatch_async_main(^{
        if (textField.tag >= SCUSignUpTextFieldTagEmail)
        {
            [self.scrollView setContentOffset:CGPointMake(0, textField.tag * 20) animated:YES];
        }
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        [self scrollToTop];
        [textField resignFirstResponder];
        [self handleCreateAccount:self.signUp];
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

- (void)scrollToTop
{
    [self.view endEditing:YES];
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    self.scrollView.scrollEnabled = NO;
}

- (void)setScrollViewSize
{
    CGSize size = [[UIScreen mainScreen] bounds].size;
    size.height += 20;
    self.scrollView.contentSize = size;
}

- (void)validateTextField:(SCUErrorTextField *)textField
{
    NSString *text = textField.text;
    NSString *errorMessage = nil;

    switch ((SCUSignUpTextFieldTag)textField.tag)
    {
        case SCUSignUpTextFieldTagFirstName:
            if (![text length])
            {
                errorMessage = NSLocalizedString(@"Enter your first name", nil);
            }
            break;
        case SCUSignUpTextFieldTagLastName:
            if (![text length])
            {
                errorMessage = NSLocalizedString(@"Enter your last name", nil);
            }
            break;
        case SCUSignUpTextFieldTagEmail:
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
            break;
        case SCUSignUpTextFieldTagPassword:
            if (![text sav_isValidPassword])
            {
                errorMessage = NSLocalizedString(@"Enter a valid password", nil);
            }
            break;
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
                                      AppExtensionUsernameKey: self.emailField.text ? : @"",
                                      AppExtensionPasswordKey: self.passwordField.text ? : @"",
                                      AppExtensionNotesKey: @"Saved with the Savant app",
                                      AppExtensionSectionTitleKey: @"Savant Cloud",
                                      AppExtensionFieldsKey: @{
                                              @"First Name" : self.firstNameField.text ? : @"",
                                              @"Last Name" : self.lastNameField.text ? : @""
                                              }
                                      };

    // Password generation options are optional, but are very handy in case you have strict rules about password lengths
    NSDictionary *passwordGenerationOptions = @{
                                                AppExtensionGeneratedPasswordMinLengthKey: @(8),
                                                AppExtensionGeneratedPasswordMaxLengthKey: @(50)
                                                };

    SAVWeakSelf;
    [[OnePasswordExtension sharedExtension] storeLoginForURLString:@"http://www.savant.com"
                                                      loginDetails:newLoginDetails
                                         passwordGenerationOptions:passwordGenerationOptions
                                                 forViewController:self
                                                            sender:self.passwordExtension
                                                        completion:^(NSDictionary *loginDict, NSError *error) {
                                                            SAVStrongWeakSelf;
                                                            if (loginDict)
                                                            {
                                                                sSelf.emailField.text = loginDict[AppExtensionUsernameKey] ? : @"";
                                                                sSelf.passwordField.text = loginDict[AppExtensionPasswordKey] ? : @"";
                                                                sSelf.firstNameField.text = loginDict[AppExtensionReturnedFieldsKey][@"First Name"] ? : @"";
                                                                sSelf.lastNameField.text = loginDict[AppExtensionReturnedFieldsKey][@"Last Name"] ? : @"";
                                                            }
    }];
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[TTTAttributedLabel class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
