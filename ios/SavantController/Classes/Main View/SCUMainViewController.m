//
//  SCUSystemSelectorViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainViewController.h"
#import "SCUMainViewModel.h"
#import "SCUSystemSelectorSwingingContainer.h"
#import "SCUUserSelectorViewController.h"
#import "SCUSignInTableViewController.h"
#import "SCUInterface.h"
#import "SCUContentViewController.h"
#import "SCUPopoverController.h"
#import "SCULoadingView.h"
#import "SCUBackgroundHandler.h"
#import "SCULandingViewController.h"
#import "SCUNowPlayingViewController.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUMainViewController () <SCUMainViewModelDelegate, UIPopoverControllerDelegate, SCUBackgroundHandlerDelegate>

@property (nonatomic) SCUSystemSelectorSwingingContainer *systemSelectorViewController;
@property (nonatomic) SCUThemedNavigationViewController *navController;
@property (nonatomic) SCUMainViewModel *model;
@property (nonatomic) UIPopoverController *popController;
@property (nonatomic) BOOL interfaceLoaded;
@property (nonatomic) BOOL loadSplashScreen;
@property (nonatomic) SCULoadingView *loadingIndicator;

@end

@implementation SCUMainViewController

+ (instancetype)sharedInstance
{
    static SCUMainViewController *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCUMainViewController alloc] init];
    });
    return sharedInstance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[SCUBackgroundHandler sharedInstance] addDelegate:self];
    self.model = [[SCUMainViewModel alloc] init];
    self.model.delegate = self;

    if ([self.model loadPreviousConnection])
    {
        [self setReconnectLoadingIndicatorVisible:YES];
    }
    else if ([[SavantControl sharedControl] hasCloudCredentials] || [[NSUserDefaults standardUserDefaults] boolForKey:SCUSignInIsSkippedKey])
    {
        [self presentSystemSelector:SCUSystemSelectorFromLocationSignIn];
    }
    else
    {
        self.loadSplashScreen = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.loadSplashScreen)
    {
        self.loadSplashScreen = NO;
        [self presentSplashScreen];
    }
}

- (void)presentLoadingScreenWithName:(NSString *)name
{
    [self setReconnectLoadingIndicatorVisible:YES systemName:name];
}

- (void)setReconnectLoadingIndicatorVisible:(BOOL)visible systemName:(NSString *)systemName
{
    if (visible)
    {
        [self cleanup:YES];
        
        if (!self.loadingIndicator)
        {
            self.loadingIndicator = [[SCULoadingView alloc] initWithFrame:CGRectZero];
            self.loadingIndicator.title = [NSString stringWithFormat:NSLocalizedString(@"Searching for %@", nil), systemName];
            NSString *buttonTitle = [NSLocalizedString(@"Other Systems", nil) uppercaseString];
            self.loadingIndicator.buttonTitles = @[buttonTitle];
            
            SAVWeakSelf;
            self.loadingIndicator.callback = ^(NSUInteger index) {
                SAVStrongWeakSelf;
                //-------------------------------------------------------------------
                // CBP TODO: find a better place for this disconnect call.
                //-------------------------------------------------------------------
                [sSelf.model resetConnection];
                [sSelf presentSystemSelector:SCUSystemSelectorFromLocationLoadingIndicator];
            };
            
            UIView *view = [UIView sav_topView];
            
            [view addSubview:self.loadingIndicator];
            [view sav_addFlushConstraintsForView:self.loadingIndicator];
        }
    }
    else
    {
        [self cleanup:YES];
    }
}

#pragma mark - SCUViewModel methods

- (id<SCUViewModel>)viewModel
{
    return self.model;
}

#pragma mark - SCUMainViewModelDelegate methods

- (void)setReconnectLoadingIndicatorVisible:(BOOL)visible
{
    if (visible)
    {
        [self cleanup:YES];

        if (!self.loadingIndicator)
        {
            self.loadingIndicator = [[SCULoadingView alloc] initWithFrame:CGRectZero];
            self.loadingIndicator.title = [NSString stringWithFormat:NSLocalizedString(@"Searching for %@", nil), [SavantControl sharedControl].currentSystem.name];
            NSString *buttonTitle = [NSLocalizedString(@"Other Systems", nil) uppercaseString];
            self.loadingIndicator.buttonTitles = @[buttonTitle];

            SAVWeakSelf;
            self.loadingIndicator.callback = ^(NSUInteger index) {
                SAVStrongWeakSelf;
                //-------------------------------------------------------------------
                // CBP TODO: find a better place for this disconnect call.
                //-------------------------------------------------------------------
                [sSelf.model resetConnection];
                [sSelf presentSystemSelector:SCUSystemSelectorFromLocationLoadingIndicator];
            };

            UIView *view = [UIView sav_topView];

            [view addSubview:self.loadingIndicator];
            [view sav_addFlushConstraintsForView:self.loadingIndicator];
        }
    }
    else
    {
        [self cleanup:YES];
    }
}

- (void)resetSystemSelector
{
    [self.navController popToRootViewControllerAnimated:YES];

    UINavigationController *navController = (UINavigationController *)[self presentedViewController];

    if ([navController isKindOfClass:[UINavigationController class]])
    {
        if (![[navController.viewControllers firstObject] isKindOfClass:[SCULandingViewController class]])
        {
            [navController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

- (BOOL)isSystemSelectorPresented
{
    return self.navController ? YES : NO;
}

- (void)presentUserListWithTitle:(NSString *)title
{
    SCUUserSelectorViewController *viewController = [[SCUUserSelectorViewController alloc] init];
    viewController.title = title;

    [self.navController pushViewController:viewController animated:YES];
}

- (void)presentSignInForceModal:(BOOL)forceModal
{
    SCUSignInViewModel *model = [[SCUSignInViewModel alloc] initWithUser:nil];
    [self presentSignInWithModel:model forceModal:YES];
}

- (void)presentSignInWithModel:(SCUSignInViewModel *)model forceModal:(BOOL)forceModal
{
    SCUSignInTableViewController *viewController = [[SCUSignInTableViewController alloc] initWithModel:model];

    if (forceModal)
    {
        if (![self presentedViewController])
        {
            viewController.forceCancel = YES;

            SAVWeakSelf;
            viewController.sav_dismissalBlock = ^{
                SAVStrongWeakSelf;
                [[sSelf presentedViewController] dismissViewControllerAnimated:NO completion:^{
                    [sSelf presentSystemSelector:SCUSystemSelectorFromLocationInterface];
                }];
            };

            if (self.loadingIndicator)
            {
                [self setReconnectLoadingIndicatorVisible:NO];
            }

            [self presentModalViewControllerAnimated:viewController];
        }
    }
    else
    {
        UINavigationController *navigationController = (UINavigationController *)[self presentedViewController];

        if ([navigationController isKindOfClass:[UINavigationController class]])
        {
            viewController.inNavigationController = YES;

            if ([navigationController isKindOfClass:[UINavigationController class]])
            {
                [navigationController pushViewController:viewController animated:YES];
            }
        }
        else
        {
            if ([UIDevice isPhone])
            {
                [self.navController pushViewController:viewController animated:YES];
            }
            else
            {
                SAVWeakSelf;
                viewController.sav_dismissalBlock = ^{
                    [[wSelf presentedViewController] dismissViewControllerAnimated:YES completion:NULL];
                };

                [self presentModalViewControllerAnimated:viewController];
            }
        }
    }
}

- (void)presentSplashScreen
{
    [self.model resetConnection];

    BOOL present = YES;

    UINavigationController *navController = (UINavigationController *)[self presentedViewController];

    if ([navController isKindOfClass:[UINavigationController class]])
    {
        if ([[navController.viewControllers firstObject] isKindOfClass:[SCULandingViewController class]])
        {
            present = NO;
        }
        else
        {
            [navController dismissViewControllerAnimated:NO completion:NULL];
        }
    }

    if (present)
    {
        [[SCUInterface sharedInstance] teardownInstance];
        [self cleanup:YES];
        SCULandingViewController *landingViewController = [[SCULandingViewController alloc] init];
        SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:landingViewController];
        [self presentViewController:navController animated:NO completion:NULL];
    }
}

- (void)presentSystemSelector:(SCUSystemSelectorFromLocation)fromLocation
{
    [self.model resetConnection];

    if (self.interfaceLoaded || !self.navController)
    {
        [[SCUInterface sharedInstance] teardownInstance];
        [self cleanup:YES];

        self.systemSelectorViewController = [[SCUSystemSelectorSwingingContainer alloc] initWithFromLocation:fromLocation];
        [self sav_addChildViewController:self.systemSelectorViewController];
        [self.view sav_addFlushConstraintsForView:self.systemSelectorViewController.view];
        self.navController = self.systemSelectorViewController.navController;

        UINavigationController *navController = (UINavigationController *)[self presentedViewController];

        if ([navController isKindOfClass:[UINavigationController class]])
        {
            if ([[navController.viewControllers firstObject] isKindOfClass:[SCULandingViewController class]])
            {
                dispatch_next_runloop(^{
                    [self dismissViewControllerAnimated:YES completion:NULL];
                });
            }
        }
    }
    else
    {
        if ([self presentedViewController])
        {
            [[self presentedViewController] dismissViewControllerAnimated:YES completion:^{

                [self.navController popToRootViewControllerAnimated:YES];
            }];
        }
        else
        {
            [self.navController popToRootViewControllerAnimated:YES];
        }
    }

    self.interfaceLoaded = NO;
}

- (void)presentInterface
{
    if (self.systemSelectorViewController)
    {
        [self cleanup:NO];
        [[SCUInterface sharedInstance] loadInstance];
        UIViewController *oldViewController = self.systemSelectorViewController;
        UIViewController *newViewController = [SCUInterface sharedInstance].currentContentViewController;
        newViewController.view.frame = oldViewController.view.bounds;

        [oldViewController willMoveToParentViewController:nil];
        [oldViewController viewWillDisappear:YES];
        [oldViewController viewDidDisappear:YES];
        [self addChildViewController:newViewController];

        [self transitionFromViewController:oldViewController
                          toViewController:newViewController
                                  duration:.5
                                   options:UIViewAnimationOptionTransitionFlipFromLeft
                                animations:NULL
                                completion:^(BOOL finished) {
                                    [oldViewController removeFromParentViewController];
                                    [newViewController didMoveToParentViewController:self];
                                    [self.view sav_addFlushConstraintsForView:newViewController.view];
                                    self.systemSelectorViewController = nil;
                                    [[SCUInterface sharedInstance] presentNotificationService];
                                }];
    }
    else
    {
        [self cleanup:YES];
        [[SCUInterface sharedInstance] loadInstance];
        [self sav_addChildViewController:[SCUInterface sharedInstance].currentContentViewController];
        [self.view sav_addFlushConstraintsForView:[SCUInterface sharedInstance].currentContentViewController.view];
        [[SCUInterface sharedInstance] presentNotificationService];
    }

    self.interfaceLoaded = YES;
}

- (void)presentModalViewControllerAnimated:(UIViewController *)viewController
{
    SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:viewController];

    if ([UIDevice isPad])
    {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self presentViewController:navController animated:YES completion:NULL];
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popController = nil;
}

#pragma mark - SCUBackgroundHandlerDelegate methods

- (void)backgroundHandlerEnterBackground
{
    if (!self.loadingIndicator)
    {
        if ([SCUInterface sharedInstance].isInterfaceLoaded)
        {
            [self setReconnectLoadingIndicatorVisible:YES];
        }
    }
}

- (void)backgroundHandlerEnterForeground
{
    if (!self.loadingIndicator && [SCUInterface sharedInstance].isInterfaceLoaded)
    {
        [self setReconnectLoadingIndicatorVisible:YES];
    }
}

#pragma mark -

- (void)cleanup:(BOOL)cleanupAll
{
    //-------------------------------------------------------------------
    // Dismiss the SignIn view
    //-------------------------------------------------------------------

    UINavigationController *navigationController = (UINavigationController *)[self presentedViewController];

    if ([navigationController isKindOfClass:[UINavigationController class]])
    {
        UIViewController *visibleViewController = [navigationController visibleViewController];

        if ([visibleViewController isKindOfClass:[SCUSignInTableViewController class]] ||
            [visibleViewController isKindOfClass:[SCUNowPlayingViewController class]])
        {
            [[self presentedViewController] dismissViewControllerAnimated:NO completion:NULL];
        }
    }

    [self.popController dismissPopoverAnimated:YES];
    self.popController = nil;

    if (cleanupAll)
    {
        [self.systemSelectorViewController sav_removeFromParentViewController];
        self.systemSelectorViewController = nil;
    }

    [self.navController sav_removeFromParentViewController];
    self.navController = nil;

    [self.loadingIndicator setAnimationEnabled:NO];
    [self.loadingIndicator removeFromSuperview];
    self.loadingIndicator = nil;

    self.interfaceLoaded = NO;
}

- (void)startObservingConnectionStatus
{
    [self.model startObservingConnectionStatus];
}

- (void)cleanupFailedLogin
{
    [self.model cleanupFailedLogin];
}

@end
