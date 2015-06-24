//
//  SCUNotificationCreationViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationViewController.h"
#import "SCUInterface.h"
#import "SCUAnimator.h"
#import "SCUPassthroughViewController.h"

#import "SCUNavBarToolbar.h"
#import "SCUToolbarButtonAnimated.h"
#import "SCUNotificationsTableViewController.h"
#import "SCUMediaContainerViewController.h"
#import "SCUNotificationCreationTableViewController.h"
#import "SCUNotificationAddServiceTableViewController.h"
#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationCreationAddRuleTableViewController.h"
#import "SCUNotificationCreationSendOptionsTableViewController.h"
#import "SCUNotificationRoomsListTableViewController.h"
#import "SCUNotificationZonesListTableViewController.h"
#import "SCUNotificationCreationWhenTableViewController.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUNotificationCreationViewController ()

@property (nonatomic) UINavigationController *navController;
@property (nonatomic) SAVNotification *notification;
@property (nonatomic) SAVNotification *originalNotification;
@property (nonatomic) NSMutableArray *stateStack;
@property (nonatomic) SCUNotificationCreationState previousState;
@property (nonatomic) NSArray *presentContraints, *dismissConstraints;
@property (nonatomic) UINavigationController *presentedNavController;
@property (nonatomic) UIView *backdrop;
@property (nonatomic) SCUPassthroughViewController *topViewController;

@property (nonatomic, getter=isAdd) BOOL add;

@end

@implementation SCUNotificationCreationViewController

- (instancetype)initWithState:(SCUNotificationCreationState)state andNotification:(SAVNotification *)notification
{
    self = [super init];
    
    if (self)
    {
        if (notification)
        {
            self.notification = notification;
        }
        else
        {
            self.notification = [[SAVNotification alloc] init];
        }
        
        self.originalNotification = self.notification;
        self.editingNotification = [self.notification copy];
        
        self.stateStack = [@[@(SCUNotificationCreationState_NotificationsList)] mutableCopy];
        self.activeState = state;
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navController = [[SCUNotificationNavController alloc] initWithNavigationBarClass:nil toolbarClass:[SCUNavBarToolbar class]];
    [self.navController pushViewController:[self viewControllerForState:SCUNotificationCreationState_NotificationsList] animated:NO];
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

- (void)setActiveState:(SCUNotificationCreationState)activeState
{
    [self navigateToState:activeState animated:YES];
}

- (SCUNotificationCreationState)activeState
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

- (BOOL)isStateLeftView:(SCUNotificationCreationState)state
{
    BOOL isLeftView = NO;
    
    if (state == SCUNotificationCreationState_NotificationsList)
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

- (void)navigateToState:(SCUNotificationCreationState)state animated:(BOOL)animated
{
    if ([[self.stateStack lastObject] integerValue] != state)
    {
        [self.stateStack addObject:@(state)];
    }
    
    if (self.navController)
    {
        if (state == SCUNotificationCreationState_NotificationsList)
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
            
            SCUNotificationNavController *navController = [[SCUNotificationNavController alloc] initWithNavigationBarClass:nil toolbarClass:[SCUNavBarToolbar class]];
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

- (UIViewController *)viewControllerForState:(SCUNotificationCreationState)state
{
    UIViewController *viewController = nil;
    Class viewControllerClass = nil;
    SCUPassthroughViewController *passthrough = nil;
    
    switch (state)
    {
        case SCUNotificationCreationState_NotificationsList:
            viewControllerClass = NSClassFromString(@"SCUNotificationsTableViewController");
            break;
        case SCUNotificationCreationState_SelectServiceList:
            viewControllerClass = NSClassFromString(@"SCUNotificationAddServiceTableViewController");
            break;
        case SCUNotificationCreationState_AddRule:
            viewControllerClass = NSClassFromString(@"SCUNotificationCreationAddRuleTableViewController");
            break;
        case SCUNotificationCreationState_SetRooms:
            viewControllerClass = NSClassFromString(@"SCUNotificationRoomsListTableViewController");
            break;
        case SCUNotificationCreationState_SetZones:
            viewControllerClass = NSClassFromString(@"SCUNotificationZonesListTableViewController");
            break;
        case SCUNotificationCreationState_SetSend:
            viewControllerClass = NSClassFromString(@"SCUNotificationCreationSendOptionsTableViewController");
            break;
        case SCUNotificationCreationState_SetWhen:
            viewControllerClass = NSClassFromString(@"SCUNotificationCreationWhenTableViewController");
            break;
    }
    
    if (viewControllerClass)
    {
        viewController = [[viewControllerClass alloc] initWithNotification:self.notification];
    }
    
    if (viewController)
    {
        SCUNotificationCreationTableViewController *notificationTableViewController = (SCUNotificationCreationTableViewController *)viewController;
        notificationTableViewController.creationVC = self;
        
        passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:viewController];
        passthrough.backgroundColor = [[SCUColors shared] color03shade01];
		
        if ([UIDevice isPad])
        {
            passthrough.edgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        }
    }
    
    return passthrough;
}

- (void)wipeNotification
{
    self.notification = [[SAVNotification alloc] init];
    self.originalNotification = self.notification;
    self.editingNotification = [self.notification copy];
}

- (void)backdropTapped:(UITapGestureRecognizer *)gesture
{
    if ([self.topViewController.rootViewController isKindOfClass:[SCUNotificationAddServiceTableViewController class]])
    {
        SCUNotificationAddServiceTableViewController *viewController = (SCUNotificationAddServiceTableViewController *)self.topViewController.rootViewController;
        [viewController popViewControllerCanceled];
    }
    else
    {
        SCUNotificationCreationTableViewController *viewController = (SCUNotificationCreationTableViewController *)self.topViewController.rootViewController;
        [viewController popViewControllerCanceled];
    }
}

- (void)setEditingNotification:(SAVNotification *)editingNotification
{
    _editingNotification = [editingNotification copy];
    
    self.notification = editingNotification;
}

- (BOOL)notificationIsDirty
{
    return ![[self.editingNotification dictionaryRepresentation] isEqualToDictionary:[self.originalNotification dictionaryRepresentation]];
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
        if ([passthrough.rootViewController isKindOfClass:[SCUNotificationsTableViewController class]])
        {
            [self.stateStack removeAllObjects];
            self.stateStack = [@[@(SCUNotificationCreationState_NotificationsList)] mutableCopy];
            SCUNotificationsTableViewController *listVC = (SCUNotificationsTableViewController *)passthrough.rootViewController;
            [listVC forceModelToReloadData];
        }
        else
        {
            [self.stateStack removeLastObject];
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
    
    BOOL shouldAnimate = NO;
    
    if ([UIDevice isPad])
    {
        if (self.activeState == SCUNotificationCreationState_NotificationsList || self.isLeftView)
        {
            shouldAnimate = YES;
        }
    }
    else
    {
        if (self.isFirstView || self.isLeftView)
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

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsNavigation | SCUMainNavbarItemsRightButtons | SCUMainNavbarItemsNavigation;
}

- (NSArray *)mainNavbarRightButtonItems
{
    SCUToolbarButtonAnimated *add = [[SCUToolbarButtonAnimated alloc] initWithTitle:NSLocalizedString(@"Add", nil)];
    add.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    add.color = [[SCUColors shared] color01];
    add.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.6];
    add.target = self;
//    add.releaseAction = @selector(addNotification);
    
    return @[add];
}

- (NSNumber *)mainNavbarItemsRightSpacing
{
    return @0;
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

@end

@implementation SCUNotificationNavController

@end
