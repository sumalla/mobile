//
//  SCUMainViewModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainViewModel.h"
#import "SCUSignInViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUProgressBezel.h"
#import "SCUCascadingTimer.h"
#import "SCUInterface.h"
#import "SCUMainViewController.h"
@import LocalAuthentication;

#ifndef DEBUG
#import <CrashlyticsFramework/Crashlytics.h>
#import <SavantControl/SavantControlPrivate.h>
#endif

static NSString *const SCUDidShowTrialExpiredMessage = @"SCUDidShowTrialExpiredMessage";

#pragma mark - System selector

NSString *const SCUMainViewPresentSystemSelectorNotification = @"SCUMainViewPresentSystemSelectorNotification";

#pragma mark - Sign in

NSString *const SCUMainViewPresentUserSignInNotification = @"SCUMainViewPresentUserSignInNotification";
NSString *const SCUMainViewSignInUserKey = @"SCUMainViewSignInUserKey";
NSString *const SCUMainViewSignInForceModalKey = @"SCUMainViewSignInForceModalKey";

@interface SCUMainViewModel () <SystemStatusDelegate, UserLevelSecurityDelegate>

@property (nonatomic) SCUCascadingTimer *timer;
@property (nonatomic) SCUProgressBezel *progressBezel;
@property (nonatomic, weak) NSTimer *reconnectTimer;
@property (nonatomic, getter = isObservingConnectionStatus) BOOL observingConnectionStatus;

@end

@implementation SCUMainViewModel

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer invalidate];
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentSystemSelector:) name:SCUMainViewPresentSystemSelectorNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentSignIn:) name:SCUMainViewPresentUserSignInNotification object:nil];
        self.timer = [[SCUCascadingTimer alloc] init];
        [SavantControl sharedControl].pinCodeDelegate = self;
    }

    return self;
}

- (void)resetConnection
{
    [[SavantControl sharedControl] disconnect];

    if ([self.reconnectTimer isValid])
    {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

- (BOOL)loadPreviousConnection
{
    BOOL success = [[SavantControl sharedControl] loadPreviousConnection];
    
    if (success)
    {
        //-------------------------------------------------------------------
        // The interface will automatically be presented. Start a timer to
        // display the loading dialog if a connection couldn't be made after
        // a second.
        //-------------------------------------------------------------------
        SAVWeakSelf;
        self.reconnectTimer = [NSTimer sav_scheduledBlockWithDelay:1 block:^{
            [wSelf.delegate setReconnectLoadingIndicatorVisible:YES];
        }];
    }

    return success;
}

- (void)authorizeLocalUser:(void (^)(BOOL success, NSError *error))handler
{
    handler(YES, nil);
//    //-------------------------------------------------------------------
//    // Only touch ID will work for now.
//    //-------------------------------------------------------------------
//    LAContext *context = [[LAContext alloc] init];
////    context.localizedFallbackTitle = @"";
//
//    NSError *error = nil;
//
//    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
//    {
//        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"  ", nil) reply:^(BOOL success, NSError *error) {
//            if (success)
//            {
//                handler(YES, nil);
//            }
//            else
//            {
//                switch (error.code)
//                {
//                    case LAErrorAuthenticationFailed:
//                        NSLog(@"CBP____ auth failed");
//                        break;
//                    case LAErrorUserCancel:
//                        NSLog(@"CBP____ user cancel");
//                        break;
//                    case LAErrorUserFallback:
//                        NSLog(@"CBP____ user fallback");
//                        break;
//                    case LAErrorSystemCancel:
//                        NSLog(@"CBP____ system cancel;");
//                        break;
//                    case LAErrorPasscodeNotSet:
//                        NSLog(@"CBP____ passcode not set");
//                        break;
//                    case LAErrorTouchIDNotAvailable:
//                        NSLog(@"CBP____ auth available");
//                        break;
//                    case LAErrorTouchIDNotEnrolled:
//                        NSLog(@"CBP____ not enrolled");
//                        break;
//                }
//
//                handler(NO, error);
//            }
//        }];
//    }
//    else
//    {
//        handler(YES, nil);
//    }
}

#pragma mark - NSNotification handlers

- (void)presentSystemSelector:(NSNotification *)notification
{
    [self.delegate resetSystemSelector];
}

- (void)presentSignIn:(NSNotification *)notification
{
    SAVLocalUser *user = [notification userInfo][SCUMainViewSignInUserKey];
    SCUSignInViewModel *model = [[SCUSignInViewModel alloc] initWithUser:user];
    [self.delegate presentSignInWithModel:model forceModal:[[notification userInfo][SCUMainViewSignInForceModalKey] boolValue]];
}

#pragma mark - SCUViewModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];

    [[SavantControl sharedControl] addSystemStatusObserver:self];
}

#pragma mark - SystemStatusDelegate methods

- (BOOL)didConnectToSystemWithProtocolVersion:(uint32_t)protocolVersion
{
    BOOL stayConnected = YES;

    if (protocolVersion < 2)
    {
        stayConnected = NO;

        //-------------------------------------------------------------------
        // CBP TODO: This error log sucks.
        //-------------------------------------------------------------------
        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"Please update '%@' to 7.0.", nil), [SavantControl sharedControl].currentSystem.name]
                                                         buttonTitles:@[NSLocalizedString(@"OK", nil)]];

        [alertView show];

        dispatch_next_runloop(^{
            [[SavantControl sharedControl] disconnect];
            [self.delegate presentSystemSelector:SCUSystemSelectorFromLocationInterface];
        });
    }

    return stayConnected;
}

- (void)connectionDidConnect
{
    [self.reconnectTimer invalidate];
}

- (void)connectionDidStartConfigurationDownload
{
    [self.progressBezel hide];

    NSString *hostName = [SavantControl sharedControl].currentSystem.name;

    if (!hostName)
    {
        hostName = [[[SavantControl sharedControl] currentSystem] localAddress];
    }

    self.progressBezel = [[SCUProgressBezel alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", nil), hostName]
                                                   progressStyle:SCUProgressBezelStyleBar
                                               cancelButtonTitle:NSLocalizedString(@"Stop Download", nil)];

    SAVWeakSelf;
    self.progressBezel.callback = ^(NSUInteger index) {
        //-------------------------------------------------------------------
        // CBP TODO: Finish.
        // We need to clean up tar files or something.
        //-------------------------------------------------------------------
        [[SavantControl sharedControl] disconnect];
        [wSelf.delegate presentSystemSelector:SCUSystemSelectorFromLocationInterface];
    };

    [self.progressBezel show];
}

- (void)connectionDidReceiveConfigurationDownloadUpdate:(float)progress isInstalling:(BOOL)isInstalling
{
    if (isInstalling)
    {
        self.progressBezel.stage = NSLocalizedString(@"Installing", nil);
    }
    else
    {
        self.progressBezel.stage = NSLocalizedString(@"Downloading", nil);
    }

    self.progressBezel.progress = progress;
}

- (void)connectionIsReady
{
    if (self.progressBezel)
    {
        //-------------------------------------------------------------------
        // CBP TODO: Finish.
        // The timing here needs tweaks and we need to hide alert buttons.
        //-------------------------------------------------------------------
        [self.progressBezel completeWithMessage:NSLocalizedString(@"Complete", nil)];

        SAVWeakSelf;

        [self.timer addBlockAfterDelay:0.5 block:^{
            [wSelf.progressBezel hide];
            wSelf.progressBezel = nil;
        }];

        [self.timer addBlockAfterDelay:.6 block:^{
            [wSelf.delegate presentInterface];
        }];
    }
    else
    {
        if ([SCUInterface sharedInstance].isInterfaceLoaded)
        {
            [self.delegate setReconnectLoadingIndicatorVisible:NO];
            [[SCUInterface sharedInstance] presentNotificationService];
        }
        else
        {
            SAVWeakSelf;
            [self.timer addBlockAfterDelay:.6 block:^{
                [wSelf.delegate presentInterface];
            }];
        }
    }

#ifndef DEBUG
    [Crashlytics setUserIdentifier:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    [Crashlytics setObjectValue:[SavantControl sharedControl].currentSystem.hostID forKey:@"System ID"];
    [Crashlytics setBoolValue:[SavantControl sharedControl].isDemoSystem forKey:@"Demo Mode"];

    if ([SavantControl sharedControl].cloudServerAddress > SAVCloudServerAddressProduction)
    {
        [Crashlytics setObjectValue:[SavantControl sharedControl].currentSystem.name forKey:@"System Name"];
        [Crashlytics setUserEmail:[SavantControl sharedControl].cloudUser];
        [Crashlytics setUserName:[SavantControl sharedControl].currentUserName];

        NSString *bundleVersionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];

        if (bundleVersionString)
        {
            [Crashlytics setObjectValue:bundleVersionString forKey:@"Build"];
        }
    }
#endif
}

- (void)connectionDidReceiveAuthChallengeForUser:(NSString *)user
{
    if (![self.delegate isSystemSelectorPresented])
    {
        SAVLocalUser *u = [[SAVLocalUser alloc] init];
        u.accountName = user;
        u.requiresAuthentication = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:SCUMainViewPresentUserSignInNotification
                                                            object:nil
                                                          userInfo:@{SCUMainViewSignInUserKey: u,
                                                                     SCUMainViewSignInForceModalKey: @YES}];
    }
}

- (void)establishedConnectionDidFail
{
    if ([SCUInterface sharedInstance].isInterfaceLoaded)
    {
        SAVWeakSelf;
        self.reconnectTimer = [NSTimer sav_scheduledBlockWithDelay:3 block:^{
            [wSelf.delegate setReconnectLoadingIndicatorVisible:YES];;
        }];
    }
}

- (void)connectionShouldLogOut
{
    [self.delegate presentSplashScreen];
}

- (void)connectionPermissionsDidChange
{
    if ([SCUInterface sharedInstance].isInterfaceLoaded)
    {
        [[SCUInterface sharedInstance] teardownInstance];
        [[SAVSettings localSettings] removeObjectForKey:@"CurrentService"];
        [[SAVSettings localSettings] removeObjectForKey:@"CurrentRoomGroup"];
        [[SCUMainViewController sharedInstance] presentInterface];
    }
}

- (void)connectionDidFailToConnect
{
    if ([SavantControl sharedControl].currentSystem.remoteAccessDisableReason == SAVSystemRemoteAccessDisabledReasonTrialPeriodExpired)
    {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:SCUDidShowTrialExpiredMessage])
        {
            [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
                [defaults setBool:YES forKey:SCUDidShowTrialExpiredMessage];
            }];

            NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Your 90 day trial has expired.\n", nil)
                                                                                        attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];

            [message appendAttributedString:[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"For remote access:", nil)
                                                                                   attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]}]];

            [[[SCUAlertView alloc] initErrorAlertWithMessage:[message copy]
                                                     bullets:@[NSLocalizedString(@"Savant Plus is required.", nil), NSLocalizedString(@"This app requires an update.", nil)]
                                               buttontTitles:@[NSLocalizedString(@"OK", nil)]] show];
        }
    }
}

- (void)startObservingConnectionStatus
{
    self.observingConnectionStatus = YES;
    [self connectionDidChangeToState:[SavantControl sharedControl].connectionState];
}

- (void)cleanupFailedLogin
{
    if (self.progressBezel)
    {
        [self.progressBezel hide];
        self.progressBezel = nil;
    }
}

- (void)connectionDidChangeToState:(SAVConnectionState)state
{
    if (self.observingConnectionStatus)
    {
        switch (state)
        {
            case SAVConnectionStateNotConnected:
                [[SCUInterface sharedInstance] currentContentViewController].navigationController.navigationBar.barTintColor = [UIColor redColor];
                break;
            case SAVConnectionStateLocal:
                [[SCUInterface sharedInstance] currentContentViewController].navigationController.navigationBar.barTintColor = [UIColor greenColor];
                break;
            case SAVConnectionStateCloud:
                [[SCUInterface sharedInstance] currentContentViewController].navigationController.navigationBar.barTintColor = [UIColor purpleColor];
                break;
        }
    }
}

#pragma mark - UserLevelSecurityDelegate

- (void)checkUserLevelSecurityBeforeAuthenticating:(void (^)(BOOL shouldContinue))continueBlock
{
    [self authorizeLocalUser:^(BOOL success, NSError *error) {
        continueBlock(success);
    }];
}

@end
