//
//  SCUSceneCreationViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationViewController.h"
#import "SCUAnimator.h"
#import "SCUPassthroughViewController.h"
#import "SCUSceneServiceViewController.h"
#import "SCUSceneSelectedServicesListViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUNavBarToolbar.h"
#import "SCUMediaContainerViewController.h"
#import "SCUServiceViewControllerManager.h"

@import Extensions;
@import SDK;

@interface SCUSceneCreationViewController ()

@property UINavigationController *navController;
@property SAVScene *scene;
@property SAVScene *originalScene;
@property NSMutableArray *stateStack;
@property SCUSceneCreationState previousState;
@property (getter = isAdd) BOOL add;
@property NSArray *presentContraints, *dismissConstraints;
@property UINavigationController *presentedNavController;
@property UIView *backdrop;
@property SCUPassthroughViewController *topViewController;

@end

@implementation SCUSceneCreationViewController

- (instancetype)initWithState:(SCUSceneCreationState)state andScene:(SAVScene *)scene
{
    self = [super init];
    if (self)
    {
        if (scene)
        {
            self.scene = scene;
        }
        else
        {
            self.scene = [[SAVScene alloc] init];
        }

        self.originalScene = self.scene;
        self.editingScene = [self.scene copy];

        self.stateStack = [NSMutableArray array];
        self.activeState = state;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navController = [[SCUScenesNavController alloc] initWithNavigationBarClass:nil toolbarClass:[SCUNavBarToolbar class]];
    [self.navController pushViewController:[self viewControllerForState:SCUSceneCreationState_SelectedServicesList] animated:NO];
    self.navController.view.backgroundColor = [UIColor clearColor];
    self.navController.navigationBar.translucent = NO;
    self.navController.delegate = self;
    [self sav_addChildViewController:self.navController];

    if ([UIDevice isPad])
    {
        [self.view sav_pinView:self.navController.view withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsVertically];
        [self.view sav_setWidth:.42 forView:self.navController.view isRelative:YES];

        self.view.backgroundColor = [UIColor clearColor];
    }
    else
    {
        [self.view sav_addFlushConstraintsForView:self.navController.view];
    }

    if (self.activeState)
    {
        [self navigateToState:self.activeState animated:NO];
    }
}

- (void)setupToolbar
{
    [self.navController.toolbar setBackgroundImage:[UIImage resizableImageOfColor:[UIColor colorWithHue:22 saturation:100 brightness:100 alpha:1] initialSize:1] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];

    CGRect frame = self.navController.toolbar.frame;
    frame.size.height = 60;
    frame.origin.y = CGRectGetHeight(self.navController.view.frame) - 60;
    self.navController.toolbar.frame = frame;
}

- (void)setActiveState:(SCUSceneCreationState)activeState
{
    [self navigateToState:activeState animated:YES];
}

- (SCUSceneCreationState)activeState
{
    return [[self.stateStack lastObject] integerValue];
}

- (NSArray *)states
{
    return [self.stateStack copy];
}

- (BOOL)isFirstView
{
    BOOL isFirstView = [self.stateStack count] == 1;

    if ([self isStateLeftView:[[self.stateStack firstObject] integerValue]])
    {
        isFirstView = [self.stateStack count] == 2;
    }

    return isFirstView;
}

- (BOOL)isStateLeftView:(SCUSceneCreationState)state
{
    BOOL isLeftView = NO;

    if (state == SCUSceneCreationState_AddServicesList ||
        state == SCUSceneCreationState_Capture ||
        state == SCUSceneCreationState_Save)
    {
        isLeftView = YES;
    }

    return isLeftView;
}

- (BOOL)isLeftView
{
    return [self isStateLeftView:self.activeState];
}

- (UIView *)presentationView
{
    return self.view;
}

- (void)navigateToState:(SCUSceneCreationState)state animated:(BOOL)animated
{
    if ([[self.stateStack lastObject] integerValue] != state)
    {
        [self.stateStack addObject:@(state)];
    }

    if (self.navController)
    {
        if (state == SCUSceneCreationState_AddServicesList)
        {
            self.add = YES;
        }

        UIViewController *viewController = [self viewControllerForState:state];

        if ([UIDevice isPad] && self.isFirstView)
        {
            if (!self.backdrop)
            {
                self.backdrop = [[UIView alloc] init];
                self.backdrop.backgroundColor = [[SCUColors shared] color03];
                self.backdrop.hidden = YES;
                
                [self.presentationView addSubview:self.backdrop];
                [self.presentationView sav_addFlushConstraintsForView:self.backdrop];
            }

            SCUScenesNavController *navController = [[SCUScenesNavController alloc] initWithNavigationBarClass:nil toolbarClass:[SCUNavBarToolbar class]];
            navController.delegate = self;
            navController.navigationBar.translucent = NO;
            [navController pushViewController:viewController animated:NO];

            self.presentedNavController = navController;

            [self.presentationView addSubview:navController.view];

            [self.presentationView sav_setWidth:.58 forView:navController.view isRelative:YES];
            [self.presentationView sav_pinView:navController.view withOptions:SAVViewPinningOptionsToRight];
            [self.presentationView sav_pinView:navController.view withOptions:SAVViewPinningOptionsToRight ofView:self.navController.view withSpace:0];

            self.presentContraints = [NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                              views:@{@"view": navController.view}
                                                                            formats:@[@"V:|[view]|"]];

            self.dismissConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                               views:@{@"view": navController.view}
                                                                             formats:@[@"view.height = super.height",
                                                                                       @"view.top = super.bottom"]];
            self.backdrop.hidden = NO;

            if (animated)
            {
                [self.presentationView addConstraints:self.dismissConstraints];
                self.backdrop.alpha = 0;

                [self.presentationView layoutIfNeeded];

                [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.backdrop.alpha = .9;

                    [self.presentationView removeConstraints:self.dismissConstraints];
                    [self.presentationView addConstraints:self.presentContraints];
                    
                    [self.presentationView layoutIfNeeded];
                } completion:NULL];
            }
            else
            {
                self.backdrop.alpha = .9;
                [self.view addConstraints:self.presentContraints];
            }
        }
        else
        {
            UINavigationController *navController = self.navController;

            if (self.presentedNavController)
            {
                navController = self.presentedNavController;
            }

            [navController pushViewController:viewController animated:animated];
        }
    }
}

- (UIViewController *)viewControllerForState:(SCUSceneCreationState)state
{
    UIViewController *viewController = nil;
    Class viewControllerClass = nil;
    SCUPassthroughViewController *passthrough = nil;

    switch (state)
    {
        case SCUSceneCreationState_RoomsList:
            viewControllerClass = NSClassFromString(@"SCUSceneRoomsListViewController");
            break;
        case SCUSceneCreationState_ZonesList:
            viewControllerClass = NSClassFromString(@"SCUSceneZonesListViewController");
            break;
        case SCUSceneCreationState_Save:
            viewControllerClass = NSClassFromString(@"SCUSceneSaveViewController");
            break;
        case SCUSceneCreationState_Service:
            if (self.editingServiceGroup)
            {
                viewController = [SCUServiceViewControllerManager sceneServiceViewControllerForServiceGroup:self.editingServiceGroup scene:self.editingScene];
            }
            else
            {
                viewController = [SCUServiceViewControllerManager sceneServiceViewControllerForService:self.editingService scene:self.editingScene];
            }
            if (viewController)
            {
                break;
            }
        case SCUSceneCreationState_ServiceRoom:
            viewControllerClass = NSClassFromString(@"SCUSceneServiceRoomViewController");
            break;
        case SCUSceneCreationState_AddServicesList:
            viewControllerClass = NSClassFromString(@"SCUSceneAddServicesListViewController");
            break;
        case SCUSceneCreationState_SelectedServicesList:
            viewControllerClass = NSClassFromString(@"SCUSceneSelectedServicesListViewController");
            break;
        case SCUSceneCreationState_PowerOff:
            viewControllerClass = NSClassFromString(@"SCUScenePowerOffViewController");
            break;
        case SCUSceneCreationState_Schedule:
            viewControllerClass = NSClassFromString(@"SCUSceneScheduleViewController");
            break;
        case SCUSceneCreationState_Capture:
            viewControllerClass = NSClassFromString(@"SCUSceneCaptureViewController");
            break;
        case SCUSceneCreationState_FadeTime:
            viewControllerClass = NSClassFromString(@"SCUSceneFadeTimeViewController");
            break;
    }

    if (viewControllerClass)
    {
        viewController = [[viewControllerClass alloc] initWithScene:self.editingScene andService:self.editingService];
    }

    if (viewController)
    {
        SCUSceneCreationTableViewController *sceneTableVC = (SCUSceneCreationTableViewController *)viewController;
        sceneTableVC.creationVC = self;
        
        passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:viewController];
        passthrough.backgroundColor = [[SCUColors shared] color03shade01];

        if ([UIDevice isPad])
        {
            passthrough.edgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        }
    }

    return passthrough;
}

- (void)backdropTapped:(UITapGestureRecognizer *)gesture
{
    if ([self.topViewController.rootViewController isKindOfClass:[SCUSceneServiceViewController class]])
    {
        SCUSceneServiceViewController *viewController = (SCUSceneServiceViewController *)self.topViewController.rootViewController;
        [viewController popViewControllerCanceled];
    }
    else
    {
        SCUSceneCreationTableViewController *viewController = (SCUSceneCreationTableViewController *)self.topViewController.rootViewController;
        [viewController popViewControllerCanceled];
    }
}

- (void)setEditingScene:(SAVScene *)editingScene
{
    _editingScene = [editingScene copy];

    self.scene = editingScene;
}

- (BOOL)sceneIsDirty
{
    return ![[self.editingScene dictionaryRepresentation] isEqualToDictionary:[self.originalScene dictionaryRepresentation]];
}

- (void)viewControllerDidCancel:(UIViewController *)viewController
{
    [self viewControllerDidDismiss:viewController canceled:YES];
}

- (void)viewControllerDidDismiss:(UIViewController *)viewController
{
    [self viewControllerDidDismiss:viewController canceled:NO];
}

- (void)viewControllerDidDismiss:(UIViewController *)viewController canceled:(BOOL)canceled
{
    [self.presentationView layoutIfNeeded];
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.backdrop.alpha = 0;

        [self.presentationView removeConstraints:self.presentContraints];
        [self.presentationView addConstraints:self.dismissConstraints];

        [self.presentationView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.presentedNavController.view removeFromSuperview];
        self.backdrop.hidden = YES;
        self.presentedNavController = nil;
    }];

    if ([UIDevice isPad] && ![self.navController.topViewController isEqual:viewController] && !canceled)
    {
        [self.navController popToRootViewControllerAnimated:YES];
    }
    else
    {
        UITableViewController *tableVC = (UITableViewController *)[(SCUPassthroughViewController *)self.navController.topViewController rootViewController];
        [tableVC viewWillAppear:NO];
    }

    SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.navController.topViewController;

    [self poppedToViewController:passthrough];
}

- (void)poppedToViewController:(SCUPassthroughViewController *)passthrough
{
    if (![self.topViewController.rootViewController isKindOfClass:[SCUMediaContainerViewController class]])
    {
        if ([passthrough.rootViewController isKindOfClass:[SCUSceneSelectedServicesListViewController class]])
        {
            [self.stateStack removeAllObjects];
        }
        else
        {
            [self.stateStack removeLastObject];
        }

        if (self.activeState == SCUSceneCreationState_SelectedServicesList)
        {
            self.add = NO;
            self.envAdd = NO;
            self.editingService = nil;
            self.editingServiceGroup = nil;
            self.editingScene = self.editingScene;

            SCUSceneSelectedServicesListViewController *vc = (SCUSceneSelectedServicesListViewController *)passthrough.rootViewController;
            if ([vc isKindOfClass:[SCUSceneSelectedServicesListViewController class]])
            {
                vc.scene = self.scene;
            }
        }
        else if (self.activeState == SCUSceneCreationState_AddServicesList)
        {
            self.envAdd = NO;
            self.add = NO;
            self.editingServiceGroup = nil;
            self.editingService = nil;
        }
    }
}

#pragma mark - Navigation Controller Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSInteger newViewControllerCount = [navigationController.viewControllers count];

    if (newViewControllerCount < [navigationController.sav_viewControllersCount integerValue])
    {
        SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)viewController;

        [self poppedToViewController:passthrough];
    }

    self.topViewController = (SCUPassthroughViewController *)viewController;

    navigationController.sav_viewControllersCount = @(newViewControllerCount);
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                 animationControllerForOperation:(UINavigationControllerOperation)operation
                                              fromViewController:(UIViewController *)fromVC
                                                toViewController:(UIViewController *)toVC
{
    SCUAnimator *animator = [[SCUAnimator alloc] init];
    SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)toVC;

    BOOL shouldAnimate = NO;

    if ([UIDevice isPad])
    {
        if (([self.editingService.serviceId hasPrefix:@"SVC_ENV"] && self.activeState == SCUSceneCreationState_Service) ||
            self.activeState == SCUSceneCreationState_Schedule ||
            self.isLeftView ||
            [passthrough.rootViewController isKindOfClass:[SCUSceneSelectedServicesListViewController class]])
        {
            shouldAnimate = YES;
        }
    }
    else
    {
        if (([self.editingService.serviceId hasPrefix:@"SVC_ENV"] && self.activeState == SCUSceneCreationState_Service) ||
            [passthrough.rootViewController isKindOfClass:[SCUSceneSelectedServicesListViewController class]] ||
            self.isFirstView || self.isLeftView)
        {
            shouldAnimate = YES;
        }
    }

    switch (operation)
    {
        case UINavigationControllerOperationPush:
            animator.type = SCUAnimatorTypePresent;
            break;
        case UINavigationControllerOperationPop:
            animator.type = SCUAnimatorTypeDismiss;
            break;
    }

    return shouldAnimate ? animator : nil;
}

@end

@implementation SCUScenesNavController

@end