//
//  SCUSystemSelectorViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"
#import "SCUThemedNavigationViewController.h"

typedef NS_ENUM(NSUInteger, SCUSystemSelectorFromLocation)
{
    SCUSystemSelectorFromLocationLoadingIndicator,
    SCUSystemSelectorFromLocationSignIn,
    SCUSystemSelectorFromLocationInterface
};

@interface SCUMainViewController : SCUModelViewController

@property (readonly) SCUThemedNavigationViewController *navController;
@property (readonly) UIPopoverController *popController;

+ (instancetype)sharedInstance;

- (void)presentLoadingScreenWithName:(NSString *)name;
- (void)presentSplashScreen;
- (void)presentSystemSelector:(SCUSystemSelectorFromLocation)fromLocation;
- (void)presentUserListWithTitle:(NSString *)title;
- (void)presentSignInForceModal:(BOOL)forceModal;
- (void)presentInterface;

- (void)startObservingConnectionStatus;
- (void)cleanupFailedLogin;

@end
