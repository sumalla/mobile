//
//  SCUCloudSignUpSuccessViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCloudSignUpSuccessViewController.h"
#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControlPrivate.h>
#import "SCUMainViewController.h"
#import "SCUAlertView.h"

@interface SCUCloudSignUpSuccessViewController ()

@property (nonatomic) NSString *email;

@end

@implementation SCUCloudSignUpSuccessViewController

- (instancetype)initWithEmail:(NSString *)email
{
    self = [super init];

    if (self)
    {
        self.email = email;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"SavantLogo" tintColor:[[SCUColors shared] color03shade06]]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logo];
    [self.view sav_pinView:logo withOptions:SAVViewPinningOptionsHorizontally];

    if ([UIDevice isPad])
    {
        [self.view sav_pinView:logo withOptions:SAVViewPinningOptionsToTop withSpace:150];
    }
    else
    {
        [self.view sav_pinView:logo withOptions:SAVViewPinningOptionsToTop withSpace:100];
    }

    UIView *container = [UIView sav_viewWithColor:[[SCUColors shared] color03shade03]];
    [self.view addSubview:container];
    [self.view sav_pinView:container withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:container withOptions:SAVViewPinningOptionsToBottom ofView:logo withSpace:50];
    [self.view sav_setHeight:150 forView:container isRelative:NO];

    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    welcomeLabel.text = NSLocalizedString(@"Welcome Home", nil);
    welcomeLabel.textColor = [[SCUColors shared] color01];
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    [container addSubview:welcomeLabel];

    [container sav_pinView:welcomeLabel withOptions:SAVViewPinningOptionsHorizontally];
    [container sav_pinView:welcomeLabel withOptions:SAVViewPinningOptionsToTop withSpace:20];

    UILabel *message = [[UILabel alloc] initWithFrame:CGRectZero];
    message.textColor = [[SCUColors shared] color03shade07];
    message.numberOfLines = 0;
    message.text = [NSString stringWithFormat:NSLocalizedString(@"An email has been sent to %@. Check your email to confirm.", nil), self.email];
    message.textAlignment = NSTextAlignmentCenter;
    message.lineBreakMode = NSLineBreakByWordWrapping;
    message.font = [UIFont systemFontOfSize:14];
    [container addSubview:message];
    [container sav_pinView:message withOptions:SAVViewPinningOptionsToLeft withSpace:40];
    [container sav_pinView:message withOptions:SAVViewPinningOptionsToRight withSpace:40];
    [container sav_pinView:message withOptions:SAVViewPinningOptionsToBottom ofView:welcomeLabel withSpace:SAVViewAutoLayoutStandardSpace];
    [container sav_pinView:message withOptions:SAVViewPinningOptionsToBottom];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Continue", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(verifyAccount:)];
}

- (void)cancel
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)verifyAccount:(UIBarButtonItem *)item
{
    SAVCredentialManager *credentialManager = [SavantControl sharedControl].credentialManager;
    SAVCloudServices *scs = [SavantControl sharedControl].scs;
    NSString *email = credentialManager.cloudEmail;
    NSString *password = credentialManager.cloudPassword;
    SAVWeakSelf;
    [scs loginWithEmail:email password:password completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        if (success)
        {
            [[SCUMainViewController sharedInstance] presentSystemSelector:SCUSystemSelectorFromLocationSignIn];
        }
        else
        {
            [wSelf presentEmailVerificationAlert];
        }
    }];
}

- (void)presentEmailVerificationAlert
{
    NSString *title = NSLocalizedString(@"Sign In Error", nil);
    NSString *message = NSLocalizedString(@"Please make sure your account is verified. Another email will be sent.", nil);

    SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:title
                                                          message:message
                                                     buttonTitles:@[NSLocalizedString(@"OK", nil)]];

    [alertView show];
}

@end
