//
//  SCUContentViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUContentViewController.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUToolbar.h"
#import "SCUNavigationBar.h"
#import "SCUPassthroughViewController.h"
#import "SCUMainToolbarManager.h"
#import "SCUDrawerViewController.h"
#import "SCUServiceSelectorViewController.h"
#import "SCUServiceViewController.h"
#import "SCUServiceTabBarController.h"
#import "SCUServiceCollectionViewController.h"
#import "SCUAVSettingsTableViewController.h"
#import "SCUMainViewController.h"
#import "SCUGradientView.h"
#import "SCUEmptyGradientViewController.h"
#import <SavantControl/SavantControl.h>
#import "SCUNavigationMenuViewController.h"
#import "SCURootViewController.h"
#import "SCUHomePageCollectionViewController.h"
#import "SCUNavBarToolbar.h"
#import "SCUToolbarButton.h"
#import "SCUMediaContainerViewController.h"
#import "SCUServicesFirstContainerViewController.h"
#import "SCUInterface.h"
#import "SCUAnalytics.h"
#import "SCUButton.h"

@interface SCUContentViewController () <SCUDrawerViewControllerDelegate, SAVNavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) SCUDrawerViewController *drawerController;
@property (nonatomic) SCURootViewController *rootViewController;
@property (nonatomic) SCUThemedNavigationViewController *navController;
@property (nonatomic, weak) SCUServiceViewController *activeServiceVC;

@end

@implementation SCUContentViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.rootViewController = [[SCURootViewController alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self presentViewController:self.rootViewController];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        [self openLeftDrawer];
    }
}

- (SCUServiceViewController *)currentServiceViewController
{
    return self.activeServiceVC;
}

- (SCUDrawerViewController *)currentDrawerViewController
{
    return self.drawerController;
}

- (SCURootViewController *)currentRootviewController
{
    return self.rootViewController;
}

- (void)leaveServiceScreenAnimated:(BOOL)animated
{
    UIViewController *viewController = [self.navController.viewControllers firstObject];

    if ([self.navController.viewControllers count] > 1)
    {
        SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.navController.viewControllers[1];
        if ([passthrough.rootViewController isKindOfClass:[SCUHomePageCollectionViewController class]])
        {
            viewController = passthrough;
        }
    }

    [self.navController popToViewController:viewController animated:animated];
}

- (void)presentViewController:(UIViewController<SCUMainToolbarManager> *)vc
{
    [self presentViewController:vc animated:YES];
}

- (void)presentViewController:(UIViewController <SCUMainToolbarManager> *)vc animated:(BOOL)animated
{
    SCUPassthroughViewController *viewController = [[SCUPassthroughViewController alloc] initWithRootViewController:vc];

    if (self.navController)
    {
        [self.navController pushViewController:viewController animated:animated];
    }
    else
    {
        self.navController = [[SCUThemedNavigationViewController alloc] initWithNavigationBarClass:[SCUNavigationBar class] toolbarClass:[SCUNavBarToolbar class]];
        [self.navController pushViewController:viewController animated:NO];
        [self.navController addDelegate:self];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.navController.navigationBar addGestureRecognizer:longPress];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCrazyAmountsOfTaps:)];
        tapGesture.numberOfTapsRequired = 20;
        tapGesture.delegate = self;
        [self.navController.navigationBar addGestureRecognizer:tapGesture];
        
        self.drawerController = [[SCUDrawerViewController alloc] initWithRootViewController:self.navController];
        self.drawerController.maximumAnimationDuration = 0.2;
        self.drawerController.delegate = self;
        self.drawerController.positionAboveDrawerBelowNavBar = YES;
        self.drawerController.edgeDraggingThreshold = .07;

        if ([UIDevice isPad])
        {
            self.drawerController.openWidthPercentage = 1;
            self.drawerController.maximumDrawerOpenWidth = 400;
        }
        else
        {
            if (CGRectGetWidth([[UIScreen mainScreen] bounds]) > 320)
            {
                self.drawerController.edgeDraggingThreshold = .1;
            }
        }

        SCUNavigationMenuViewController *navMenu = [[SCUNavigationMenuViewController alloc] init];
        [self.drawerController setViewController:navMenu forSide:SCUDrawerSideLeft level:SCUDrawerLevelBelow];

        SCUServiceSelectorViewController *serviceSelector = [[SCUServiceSelectorViewController alloc] init];
        [self.drawerController setViewController:serviceSelector forSide:SCUDrawerSideRight level:SCUDrawerLevelAbove];

        [self sav_addChildViewController:self.drawerController];
        [self.view sav_addFlushConstraintsForView:self.drawerController.view];
    }
}

- (void)presentServiceViewController:(SCUServiceViewController <SCUMainToolbarManager> *)vc animated:(BOOL)animated
{
    if (vc)
    {
        SAVWeakSelf;
        dispatch_block_t block = ^{

            UIViewController *topVC = [self topViewController];

            BOOL present = NO;

            if (!self.activeServiceVC || [self isViewControllerAServiceScreen:topVC])
            {
                if ([topVC respondsToSelector:@selector(model)])
                {
                    SAVFunctionForSelector(getModel, topVC, @selector(model), SCUServiceViewModel *);
                    SCUServiceViewModel *model = getModel(topVC, @selector(model));

                    if (![model.service.serviceString isEqual:vc.model.service.serviceString])
                    {
                        present = YES;
                    }
                }
                else
                {
                    present = YES;
                }
            }

            if (present)
            {
                [wSelf leaveServiceScreenAnimated:NO];
                [wSelf presentViewController:vc animated:animated];
                self.activeServiceVC = vc;
            }
        };
        
        if (self.drawerController.isOpen)
        {
            [self.drawerController closeDrawerAnimated:animated completion:block];
        }
        else
        {
            block();
        }
    }
}

#pragma mark - Navigation Controller Delegate

- (void)navigationController:(UINavigationController *)navigationController willPopToViewController:(UIViewController *)viewController
{
    if ([self.navController.topViewController isKindOfClass:[SCUPassthroughViewController class]])
    {
        SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.navController.topViewController;
        viewController = passthrough.rootViewController;
    }

    if ([viewController isKindOfClass:[SCUHomeCollectionViewController class]] ||
        [viewController isKindOfClass:[SCURootViewController class]])
    {
        [SCUInterface sharedInstance].currentService = nil;
    }
}

#pragma mark - SCUDrawerViewControllerDelegate

- (BOOL)shouldDrawer:(SCUDrawerViewController *)drawer beginDraggingFromSide:(SCUDrawerSide)drawerSide
{
    BOOL allowDragging = NO;

    UIViewController *viewController = [self topViewController];

    if (drawerSide == SCUDrawerSideLeft && [viewController isKindOfClass:[SCURootViewController class]])
    {
        allowDragging = YES;
    }
    else if (drawerSide == SCUDrawerSideRight && [self isViewControllerAServiceScreen:viewController])
    {
        SCUServiceViewController *serviceViewController = (SCUServiceViewController *)viewController;
        BOOL isServicesFirst = [serviceViewController respondsToSelector:@selector(isServicesFirst)] && serviceViewController.isServicesFirst;
        allowDragging = isServicesFirst ? NO : YES;

        if (allowDragging && self.rootViewController.activeVC != self.rootViewController.viewControllers[SCURootViewActiveTabRooms])
        {
            allowDragging = NO;
        }
    }

    return allowDragging;
}

- (void)drawer:(SCUDrawerViewController *)drawer isAnimatingSide:(SCUDrawerSide)drawerSide percentOpen:(CGFloat)percentComplete
{
    SCUToolbarButton *button = nil;

    if (drawerSide == SCUDrawerSideLeft)
    {
        button = ((SCUNavigationBar *)self.navController.navigationBar).navigationButton;
    }
    else if (drawerSide == SCUDrawerSideRight)
    {
        button = ((SCUNavigationBar *)self.navController.navigationBar).serviceSelectorButton;
    }

    if (button)
    {
        button.color = [[[SCUColors shared] color04] sav_blendColor:[[SCUColors shared] color01] intensity:percentComplete];
    }
}

#pragma mark - Toolbar items

- (void)presentServiceSelector:(UIBarButtonItem *)sender
{
    if (self.drawerController.isOpen)
    {
        dispatch_block_t completionHandler = NULL;

        if (self.drawerController.openSide == SCUDrawerSideLeft)
        {
            completionHandler = ^{
                [self.drawerController openDrawerFromSide:SCUDrawerSideRight animated:YES completion:NULL];
            };
        }

        [self.drawerController closeDrawerAnimated:YES completion:completionHandler];
    }
    else
    {
        [self.drawerController openDrawerFromSide:SCUDrawerSideRight animated:YES completion:NULL];
    }
}

#pragma mark - Overrides

- (UINavigationController *)navigationController
{
    return self.navController;
}

#pragma mark - 

- (UIViewController *)topViewController
{
    UIViewController *viewController = nil;

    if ([self.navController.topViewController isKindOfClass:[SCUPassthroughViewController class]])
    {
        SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.navController.topViewController;
        viewController = passthrough.rootViewController;

        if ([viewController isKindOfClass:[SCUMediaContainerViewController class]] &&
            [self.navController.viewControllers count] > 2)
        {
            passthrough = self.navController.viewControllers[2];
            viewController = passthrough.rootViewController;
        }
    }
    else
    {
        viewController = self.navController.topViewController;
    }

    return viewController;
}

- (BOOL)isViewControllerAServiceScreen:(UIViewController *)viewController
{
    BOOL isAServiceScreen = NO;

    if ([viewController isKindOfClass:[SCURootViewController class]])
    {
        if ([self.rootViewController.activeVC isKindOfClass:[SCUServicesFirstContainerViewController class]])
        {
            isAServiceScreen = YES;
        }
    }
    else if ([viewController isKindOfClass:[SCUServiceViewController class]] ||
        [viewController isKindOfClass:[SCUServiceTabBarController class]] ||
        [viewController isKindOfClass:[SCUServiceCollectionViewController class]] ||
        [viewController isKindOfClass:[SCUMediaContainerViewController class]])
    {
        isAServiceScreen = YES;
    }

    return isAServiceScreen;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        [self openLeftDrawer];
    }
}

- (void)handleCrazyAmountsOfTaps:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        [[SCUMainViewController sharedInstance] startObservingConnectionStatus];
    }
}

- (void)openLeftDrawer
{
    if (self.currentDrawerViewController.isOpen)
    {
        if (self.currentDrawerViewController.openSide == SCUDrawerSideRight)
        {
            [self.currentDrawerViewController closeDrawerAnimated:YES completion:^{
                [self.currentDrawerViewController openDrawerFromSide:SCUDrawerSideLeft animated:YES completion:NULL];
            }];
        }
    }
    else
    {
        [self.currentDrawerViewController openDrawerFromSide:SCUDrawerSideLeft animated:YES completion:NULL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [UIImage sav_clearImageCache];
    [[SavantControl sharedControl].imageModel purgeMemory];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[SCUButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
