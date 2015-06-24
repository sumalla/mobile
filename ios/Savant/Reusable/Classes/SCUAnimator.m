//
//  SCUAnimator.m
//  SavantController
//
//  Created by Nathan Trapp on 7/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAnimator.h"

@implementation SCUAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.type == SCUAnimatorTypeDismiss ? .2 : .35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIViewController *animatingViewController = nil;
    switch (self.type)
    {
        case SCUAnimatorTypeDismiss:
            animatingViewController = fromViewController;
            break;

        case SCUAnimatorTypePresent:
            animatingViewController = toViewController;
            break;
    }

    CGRect endFrame = animatingViewController.view.frame;
    CGRect startFrame = animatingViewController.view.frame;

    [containerView addSubview:toViewController.view];

    UIViewAnimationOptions curve = UIViewAnimationOptionCurveEaseOut;

    switch (self.type)
    {
        case SCUAnimatorTypeDismiss:
            endFrame.origin.y += CGRectGetHeight(fromViewController.view.frame);
            [containerView sendSubviewToBack:toViewController.view];
            [containerView addSubview:fromViewController.view];
            curve = UIViewAnimationOptionCurveEaseInOut;
            break;

        case SCUAnimatorTypePresent:
            startFrame.origin.y += CGRectGetHeight(fromViewController.view.frame);
            break;
    }

    animatingViewController.view.frame = startFrame;


    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:curve animations:^{
        animatingViewController.view.frame = endFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end
