//
//  SCUTVOverlayTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowTableViewController.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowAnimationController.h"
#import "SCUServiceTabBarController.h"
#import "SCUOverflowViewController.h"
#import "SCUButton.h"
#import "SCUToolbar.h"

@interface SCUOverflowDummyViewController () <UIViewControllerTransitioningDelegate, SCUOverflowPresentationDelegate>

@property (nonatomic) SCUOverflowViewController *viewController;
@property (nonatomic) UINavigationController *navController;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) SCUServiceTabBarController *controller;

@end

@implementation SCUOverflowDummyViewController

- (instancetype)initWithService:(SAVService *)service andTableViewController:(SCUOverflowTableViewController *)tableView
{
    self = [self initWithService:service];
    
    if (self)
    {
        self.viewController = [[SCUOverflowViewController alloc] initWithService:service andTableViewController:tableView];
        self.viewController.delegate = self;
    }
    
    return self;
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.model.shouldPowerOn = NO;
        self.hasCustomPresentation = YES;
        self.customPresentationStyle = [UIDevice isPad] ? UIModalPresentationCustom : UIModalPresentationOverFullScreen;
        
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.75];
        self.backgroundView.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewController)];
        [self.backgroundView addGestureRecognizer:tap];
    }
    
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    return [[SCUOverflowAnimationController alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[SCUOverflowAnimationController alloc] initWithReverse:YES];
}

#pragma mark - SCUTabBarControllerContentView methods

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"hotdog"];
}

- (void)presentCustomView
{    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    navController.modalPresentationStyle = self.customPresentationStyle;
    
    if ([UIDevice isPad])
    {
        navController.transitioningDelegate = self;
        [self.navigationController.topViewController.view addSubview:self.backgroundView];
        [self.navigationController.topViewController.view sav_addFlushConstraintsForView:self.backgroundView];

        navController.navigationBarHidden = YES;

        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:15 options:0 animations:^{
            self.backgroundView.alpha = 1.0;
        } completion:nil];
    }

    [self presentViewController:navController animated:YES completion:nil];

}

- (void)dismissViewController
{
    [self.viewController dismissViewControllerAnimated:YES completion:^ {
        [self willDismissViewControllerWithCancelled:YES];
    }];
}

- (void)willDismissViewControllerWithCancelled:(BOOL)cancel
{
    if (self.preferredIndex && ((long)self.tabController.viewControllers.count > self.preferredIndex) && !cancel)
    {
        self.tabController.activeVC = self.tabController.viewControllers[self.preferredIndex];
    }
    
    if ([UIDevice isPad])
    {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:15 options:0 animations:^{
            self.backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.backgroundView removeFromSuperview];
        }];
    }
}

@end
