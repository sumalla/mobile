//
//  SCUTVOverlayAnimationController.h
//  SavantController
//
//  Created by Stephen Silber on 2/10/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUOverflowAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

/**
 The direction of the animation.
 */
@property (nonatomic, assign) BOOL reverse;

/**
 The animation duration.
 */
@property (nonatomic, assign) NSTimeInterval duration;

- (id)initWithReverse:(BOOL)reverse;

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView;

@end
