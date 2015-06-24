//
//  AppDelegate.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAppDelegate.h"
#import "SCUMainViewController.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUBackgroundHandler.h"
#import "SCUTestViewController.h"
#import "SCUSwipeCell.h"
#import "SCULoadingView.h"
#import "SCUGradientView.h"
#import "SCUContentViewController.h"
#import "SCUPassthroughViewController.h"
#import "SCUAVEqualizerViewController.h"
#import "SCUButton.h"
#import "SCUMediaServiceViewController.h"
#import "SCUMediaTableViewController.h"
#import "SCUServiceTabBarController.h"
#import "SCURadioNavigationViewController.h"
#import "SCUClimateModeTableViewController.h"
#import "SCUNowPlayingViewController.h"
#import "SCUPickerView.h"
#import "SCUSlider.h"
#import "SCUSystemSelectorTableViewController.h"
#import "SCUUserSelectorViewController.h"
#import "SCUUserSelectorViewController.h"
#import "SCUSignInTableViewController.h"
#import "SCUSliderWithMinMaxImageCell.h"
#import "SCUSwipeView.h"
#import "SCUDatePickerCell.h"
#import "SCUDayPickerCell.h"
#import "SCUMediaTableViewCell.h"
#import "SCUSceneCreationViewController.h"
#import "SCUSceneVariantCell.h"
#import "SCUServiceSelectorTableViewController.h"
#import "SCUNavigationMenuViewController.h"
#import "SCUSceneChildCell.h"
#import "SCUSecondsPickerCell.h"
#import "SCUDefaultCollectionViewCell.h"
#import "SCUSecurityCamerasViewController.h"
#import "SCUSchedulingEditorCollectionViewController.h"
#import "SCUStandardCollectionViewCell.h"
#import "SCUHomePageCollectionViewController.h"
#import "SCULightingTableViewController.h"
#import "SCUSceneClimatePickerCell.h"
#import "SCUAnalytics.h"
#import "SCUNotificationManager.h"
#import "UIViewController+SAVAppExtensions.h"

#import <SavantControl/SavantControlPrivate.h>
#import <SavantExtensions/SavantExtensions.h>
#import <CrashlyticsFramework/Crashlytics.h>

#ifdef DEBUG
#import <SDStatusBarManager.h>
#endif

static NSString *SCUFirstTimeLaunchEvent = @"First Time Launch";

@import ObjectiveC.message;

#define TEST_VIEW_CONTROLLER 0

#if !defined(DEBUG) && TEST_VIEW_CONTROLLER
#error You can only run tests in debug mode. Please set TEST_VIEW_CONTROLLER to 0 in SCUAppDelegate.m.
#endif

@implementation SCUAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupBackend];
    
    //JRL: setup frontend called here unless app launched in background from custom action, then it's called
    //in applicationDidEnterForeground. May break on silent notifications that launch app (we don't use silent notifs)
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive)
    {
        [self setupFrontendIfNeeded];
    }
    
    return YES;
}

- (void)setupFrontendIfNeeded
{
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
#ifdef DEBUG
        //-------------------------------------------------------------------
        // Enable the "correct" status bar for screenshots in simulator.
        //-------------------------------------------------------------------
        [[SDStatusBarManager sharedInstance] enableOverrides];
#endif
        
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
#if TEST_VIEW_CONTROLLER
        self.window.rootViewController = [[SCUTestViewController alloc] init];
#else
        [self setAppearance];
        self.window.rootViewController = [SCUMainViewController sharedInstance];
#endif
        
        UIImageView *launchView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Launch"]];
        launchView.contentMode = UIViewContentModeCenter;
        launchView.backgroundColor = [UIColor sav_colorWithRGBValue:0x696057];
        
        [self.window makeKeyAndVisible];
        
        [self.window addSubview:launchView];
        launchView.frame = self.window.frame;
        
        self.window.rootViewController.view.alpha = 0;
        
        [UIView animateWithDuration:.4
                         animations:^{
                             launchView.alpha = 0;
                             self.window.rootViewController.view.alpha = 1;
                         } completion:^(BOOL finished) {
                             [launchView removeFromSuperview];
                         }];
    });
}

- (void)setupBackend
{
    SAVCloudServerAddress address = SAVCloudServerAddressUnknown;
    
#ifdef SERVER_PRODUCTION
    address = SAVCloudServerAddressProduction;
#elif defined(SERVER_ALPHA)
    address = SAVCloudServerAddressAlpha;
#elif defined(SERVER_DEV)
    address = SAVCloudServerAddressDev1;
#elif defined(SERVER_BETA)
    address = SAVCloudServerAddressBeta;
#elif defined(SERVER_QA)
    address = SAVCloudServerAddressQA;
#elif defined(SERVER_TRAINING)
    address = SAVCloudServerAddressTraining;
#elif defined(DEBUG)
    //-------------------------------------------------------------------
    // Default to alpha for debug builds if nothing was previously specified.
    //-------------------------------------------------------------------
    if (![[NSUserDefaults standardUserDefaults] objectForKey:SAVCustomServerAddress])
    {
        [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
            [defaults setInteger:SAVCloudServerAddressAlpha forKey:SAVCustomServerAddress];
        }];
    }
#endif
    if (address != SAVCloudServerAddressUnknown)
    {
        [SavantControl sharedControl].cloudServerAddress = address;
    }
    
    //-------------------------------------------------------------------
    // Setup SavantControl.
    //-------------------------------------------------------------------
    [SavantControl sharedControl].deviceFormFactor = [UIDevice isPad] ? @"tablet" : @"phone";
    [SavantControl sharedControl].deviceManufacturer = @"Apple";
    [SavantControl sharedControl].deviceOperatingSystem = [UIDevice currentDevice].systemName;
    [SavantControl sharedControl].deviceOperatingSystemVersion = [UIDevice currentDevice].systemVersion;
    [SavantControl sharedControl].deviceName = [UIDevice currentDevice].name;
    [SavantControl sharedControl].deviceModel = [[UIDevice currentDevice] model];
    [SavantControl sharedControl].deviceModelVersion = [[UIDevice currentDevice] sav_modelVersion];
    [SavantControl sharedControl].deviceUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [SavantControl sharedControl].appName = @"Savant";
    [SavantControl sharedControl].appVersion = self.appVersion;
    
    [[SCUNotificationManager sharedInstance] start:YES];
    
    [NSUserDefaults sav_updateCacheVersion:1 forKey:@"FirstAppLaunch" updateBlock:^{
        [SCUAnalytics recordEvent:SCUFirstTimeLaunchEvent];
    }];

#ifndef DEBUG
    [Crashlytics startWithAPIKey:@"8541a39326b0cb70366637f282998bfa4cf7c5b4"];
#endif
#if TEST_VIEW_CONTROLLER
#else
    [[SCUBackgroundHandler sharedInstance] start];
#endif
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[SCUBackgroundHandler sharedInstance] willDeactivate];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[SCUBackgroundHandler sharedInstance] becomeActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[SCUBackgroundHandler sharedInstance] suspend];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self setupFrontendIfNeeded];

	//BAD USER you should not launch in landscape while in a camera view!
	if (![UIDevice isPad])
    {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    }

    [[SCUBackgroundHandler sharedInstance] resume];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Remote notification handling

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)developerToken
{
    [[SCUNotificationManager sharedInstance] updatePushNotificationToken:developerToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    ;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[SCUNotificationManager sharedInstance] handleRemoteNotification:userInfo withActionIdentifier:nil];
}

#pragma mark - Appearance

- (void)setAppearance
{
    SCUColors *colors = [SCUColors shared];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"invert"] && [colors respondsToSelector:@selector(invert)])
    {
        colors.invert = YES;

        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];

        [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
            [defaults setBool:NO forKey:@"invert"];
        }];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }

    self.window.backgroundColor = [[SCUColors shared] color03shade01];
    self.window.tintColor = [colors color04];
    
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10]];


    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBarTintColor:[colors color03shade03]];
    [[UINavigationBar appearance] setTintColor:[colors color04]];

    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];

    [[SCUSwipeCell appearance] setBackgroundColor:[colors color03shade03]];

    [[UIPageControl appearance] setBackgroundColor:[UIColor clearColor]];

    {
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor sav_colorWithRGBValue:0x696057];
        [[SCULoadingView appearance] setBackgroundView:backgroundView];
        [[SCULoadingView appearance] setBackgroundTintColor:[UIColor sav_colorWithRGBValue:0x696057]];
        [[SCULoadingView appearance] setForegroundTintColor:[[SCUColors shared] color04]];
        [[SCULoadingView appearance] setButtonColor:[UIColor clearColor]];
        [[SCULoadingView appearance] setCenterImage:[UIImage imageNamed:@"Launch"]];
    }

    [[SCUSwipeCell appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundColor:[UIColor sav_colorWithRGBValue:0x555555]];
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [colors color04],
                                                                                                              NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8]}];

    [[UINavigationBar appearanceWhenContainedIn:[SCUContentViewController class], nil] setBarStyle:UIBarStyleBlackOpaque];

    [[SCUSlider appearance] setTrackColor:[colors color03shade08]];
    [[SCUSlider appearance] setFillColor:[colors color01]];
    [[SCUSlider appearance] setThumbColor:[colors color04]];
    
    [[UISwitch appearance] setOnTintColor:[colors color01]];
    [[UISwitch appearance] setTintColor:[colors color03shade05]];
    
    [[UIToolbar appearanceWhenContainedIn:[SCUPassthroughViewController class], nil]
     setBackgroundImage:[[UIImage alloc] init]
     forToolbarPosition:UIBarPositionAny
     barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearanceWhenContainedIn:[SCUPassthroughViewController class], nil]
     setShadowImage:[[UIImage alloc] init]
     forToolbarPosition:UIBarPositionAny];

    {
        [[SCUSlider appearanceWhenContainedIn:[SCUAVEqualizerViewController class], nil] setFillColor:[colors color01]];
    }

    [[UITableView appearanceWhenContainedIn:[SCUMediaServiceViewController class], nil] setSectionIndexColor:[colors color01]];
    [[UIToolbar appearanceWhenContainedIn:[SCUServiceTabBarController class], nil] setBarTintColor:[[colors color03shade04] colorWithAlphaComponent:0.9]];

    [[SCUButton appearanceWhenContainedIn:[SCURadioNavigationViewController class], nil] setSelectedColor:[colors color01]];
    [[SCUButton appearanceWhenContainedIn:[SCURadioNavigationViewController class], nil] setSelectedBackgroundColor:nil];

    [[SCUButton appearanceWhenContainedIn:[SCUClimateModeTableViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[SCUButton appearanceWhenContainedIn:[SCUClimateModeTableViewController class], nil] setSelectedColor:[colors color01]];
    [[SCUButton appearanceWhenContainedIn:[SCUClimateModeTableViewController class], nil] setSelectedBackgroundColor:[UIColor clearColor]];

    [[SCUButton appearanceWhenContainedIn:[SCUPickerView class], nil] setBackgroundColor:nil];
    [[SCUButton appearanceWhenContainedIn:[SCUPickerView class], nil] setSelectedBackgroundColor:nil];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [[SCUColors shared] color03shade08],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateDisabled];

    UIView *selectedBackground = [[UIView alloc] init];
    selectedBackground.backgroundColor = [colors color03shade04];

    //-------------------------------------------------------------------
    // General tables
    //-------------------------------------------------------------------
    [[SCUDefaultTableViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUDefaultTableViewCell appearance] setSelectedBackgroundView:selectedBackground];
    [[SCUDefaultTableViewCell appearance] setBottomLineColor:[colors color03shade04]];
    [[SCUDefaultTableViewCell appearance] setBottomLineType:SCUDefaultTableViewCellBottomLineTypeFull];
    [[SCUDefaultTableViewCell appearance] setBorderType:SCUDefaultTableViewCellBorderTypeSection];
    [[SCUDefaultTableViewCell appearance] setBorderColor:[colors color03shade04]];
    [[UITableView appearance] setBackgroundColor:[colors color03shade01]];
    [[UITableView appearance] setSav_separatorStyle:UITableViewCellSeparatorStyleNone];
    [[UITableView appearance] setSectionIndexBackgroundColor:[UIColor clearColor]];
    [[UITableView appearance] setSectionIndexColor:[colors color01]];
    [[UITableView appearance] setSectionIndexMinimumDisplayRowCount:15];

    //-------------------------------------------------------------------
    // General collection views
    //-------------------------------------------------------------------
    [[SCUDefaultCollectionViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUDefaultCollectionViewCell appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUDefaultCollectionViewCell appearance] setBorderColor:[colors color03shade04]];
    [[SCUStandardCollectionViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUStandardCollectionViewCell appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUStandardCollectionViewCell appearance] setBorderColor:[colors color03shade04]];

    //-------------------------------------------------------------------
    // Room fullscreen view
    //-------------------------------------------------------------------
    [[SCUDefaultCollectionViewCell appearanceWhenContainedIn:[SCUHomePageCollectionViewController class], nil] setBorderWidth:0];

    //-------------------------------------------------------------------
    // Security Cameras
    //-------------------------------------------------------------------
    [[SCUDefaultCollectionViewCell appearanceWhenContainedIn:[SCUSecurityCamerasViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[SCUDefaultCollectionViewCell appearanceWhenContainedIn:[SCUSecurityCamerasViewController class], nil] setBorderWidth:0];

    //-------------------------------------------------------------------
    // Scheduling
    //-------------------------------------------------------------------
    [[SCUDefaultCollectionViewCell appearanceWhenContainedIn:[SCUSchedulingEditorCollectionViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[SCUDefaultCollectionViewCell appearanceWhenContainedIn:[SCUSchedulingEditorCollectionViewController class], nil] setBorderWidth:0];
    [[SCUDefaultTableViewCell appearanceWhenContainedIn:[SCUSchedulingEditorCollectionViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[SCUDefaultTableViewCell appearanceWhenContainedIn:[SCUSchedulingEditorCollectionViewController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeNone];

    //-------------------------------------------------------------------
    // Service selector table
    //-------------------------------------------------------------------
    [[SCUDefaultTableViewCell appearanceWhenContainedIn:[SCUServiceSelectorTableViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[SCUDefaultTableViewCell appearanceWhenContainedIn:[SCUServiceSelectorTableViewController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeNone];
    [[UITableView appearanceWhenContainedIn:[SCUServiceSelectorTableViewController class], nil] setBackgroundColor:[UIColor clearColor]];
    [[UITableView appearanceWhenContainedIn:[SCUServiceSelectorTableViewController class], nil] setSav_separatorStyle:UITableViewCellSeparatorStyleNone];

    //-------------------------------------------------------------------
    // Menu table
    //-------------------------------------------------------------------
    [[SCUDefaultTableViewCell appearanceWhenContainedIn:[SCUNavigationMenuViewController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeNone];

    //-------------------------------------------------------------------
    // Scenes
    //-------------------------------------------------------------------
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setMinImage:[UIImage sav_imageNamed:@"decreaseVolume" tintColor:[[SCUColors shared] color03shade05]]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setMaxImage:[UIImage sav_imageNamed:@"increaseVolume" tintColor:[[SCUColors shared] color03shade05]]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    //-------------------------------------------------------------------
    // Lighting
    //-------------------------------------------------------------------
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCULightingTableViewController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCULightingTableViewController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCULightingTableViewController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCULightingTableViewController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSwipeView appearance] setBackgroundColor:[[SCUColors shared] color03]];
    [[SCUSwipeView appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUSwipeView appearance] setBorderColor:[[SCUColors shared] color03shade02]];
    [[SCUSwipeView appearance] setSwipeColor:[[SCUColors shared] color01]];
    [[SCUSwipeView appearance] setArrowColor:[[SCUColors shared] color04]];
}

- (NSString *)appVersion
{
#ifdef DEBUG
    return @"Debug";
#else
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];

#ifdef SERVER_PRODUCTION
    return info[@"ActualVersion"];
#else
    NSString *server = nil;

    BOOL includeShortVersion = YES; // Jenkins inserts the branch here

#ifdef SERVER_ALPHA
    server = @"Alpha";
#elif defined(SERVER_DEV)
    server = @"Dev";
#elif defined(SERVER_BETA)
    server = @"Beta";
#elif defined(SERVER_QA)
    server = @"QA";
#elif defined(SERVER_TRAINING)
    server = @"Training";
#else
    includeShortVersion = NO;
    server = @"Unknown";
#endif

    NSString *buildNumber = info[@"CFBundleVersion"];

    if (includeShortVersion)
    {
        NSString *branch = info[@"CFBundleShortVersionString"];
        return [NSString stringWithFormat:@"%@ - %@ (%@)", server, branch, buildNumber];
    }
    else
    {
        return [NSString stringWithFormat:@"%@ (%@)", server, buildNumber];
    }
#endif
#endif
}

@end

@implementation UIFont (Gotham)

+ (void)load
{
    SAVReplaceClassMethodWithMethod([self class], @selector(systemFontOfSize:), @selector(scu_regularFontWithSize:));
    SAVReplaceClassMethodWithMethod([self class], @selector(boldSystemFontOfSize:), @selector(scu_boldFontWithSize:));
    SAVReplaceClassMethodWithMethod([self class], @selector(fontWithName:size:), @selector(scu_fontWithName:size:));
    SAVReplaceClassMethodWithMethod([self class], @selector(preferredFontForTextStyle:), @selector(scu_preferredFontForTextStyle:));
    SAVReplaceMethodWithBlock(self, NSSelectorFromString(@"_scaledValueForValue:"), ^(UIFont *font, CGFloat value){
        return value;
    });
}

+ (UIFont *)scu_preferredFontForTextStyle:(NSString *)style
{
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Medium",
                                  UIFontDescriptorSizeAttribute: @17
                                  },

                          UIFontTextStyleSubheadline: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @12
                                  },

                          UIFontTextStyleBody: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @17
                                  },

                          UIFontTextStyleCaption1: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @12
                                  },

                          UIFontTextStyleCaption2: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @11
                                  },

                          UIFontTextStyleFootnote: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @13
                                  }
                          };
    });

    return [[self class] scu_fontWithName:fontSizeTable[style][UIFontDescriptorNameAttribute] size:[fontSizeTable[style][UIFontDescriptorSizeAttribute] floatValue]];
}

+ (UIFont *)scu_regularFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Gotham-Light" size:size];
}

+ (UIFont *)scu_boldFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Gotham-Medium" size:size];
}

+ (UIFont *)scu_fontWithName:(NSString *)name size:(CGFloat)size
{
    name = [name stringByReplacingOccurrencesOfString:@"HelveticaNeue" withString:@"Gotham"];

    return [[self class] scu_fontWithName:name size:size]; // call original
}

@end
