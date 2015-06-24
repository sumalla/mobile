//
//  SCUTVOverlayAnimationController.m
//  SavantController
//
//  Created by Stephen Silber on 2/10/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowAnimationController.h"
#import "SCUOverflowViewController.h"

@import Extensions;

@implementation SCUOverflowAnimationController

- (id)initWithReverse:(BOOL)reverse
{
    self = [super init];
    
    if (self)
    {
        self.duration = 0.50f;
        self.reverse = reverse;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = toVC.view;
    UIView *fromView = fromVC.view;
    
    [self animateTransition:transitionContext fromVC:fromVC toVC:toVC fromView:fromView toView:toView];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView
{
    
    if (self.reverse)
    {
        [self executeReverseAnimation:transitionContext fromVC:fromVC toVC:toVC fromView:fromView toView:toView];
    }
    else
    {
        [self executeForwardsAnimation:transitionContext fromVC:fromVC toVC:toVC fromView:fromView toView:toView];
    }
    
}

- (void)executeForwardsAnimation:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView
{
    UIView *containerView = [transitionContext containerView];
    
    CGRect frame = [transitionContext initialFrameForViewController:fromVC];
    CGRect offScreenFrame = frame;
    offScreenFrame.origin.x = offScreenFrame.size.width;
    toView.frame = offScreenFrame;

    [containerView insertSubview:toView aboveSubview:fromView];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:5 options:0 animations:^{
        CGRect onScreenFrame = toView.frame;
        onScreenFrame.origin.x = 0;
        toView.frame = onScreenFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)executeReverseAnimation:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView
{
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:5 options:0 animations:^{
        CGRect offScreenFrame = fromView.frame;
        offScreenFrame.origin.x = CGRectGetWidth(offScreenFrame);
        fromView.frame = offScreenFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
