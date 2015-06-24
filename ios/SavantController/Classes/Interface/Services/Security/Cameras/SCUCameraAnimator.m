//
//  SCUCameraAnimator.m
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraAnimator.h"
#import "SCUCameraFullScreenViewController.h"
#import "SCUCameraCollectionViewCell.h"

@interface SCUCameraAnimator ()

@property UIImageView *transitioningImageView;

@end

@implementation SCUCameraAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return .4f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    SCUCameraFullScreenViewController *fullScreenView = self.presenting ? (SCUCameraFullScreenViewController *)toViewController : (SCUCameraFullScreenViewController *)fromViewController;
    fullScreenView.imageView.hidden = YES;

    //-------------------------------------------------------------------
    // Setup the transitioning image's frame and image
    //-------------------------------------------------------------------
    CGRect originalFrame = [self.cellImageView convertRect:self.cellImageView.bounds toView:nil];
    CGRect endFrame = fromViewController.view.bounds;

    //-------------------------------------------------------------------
    // Calculate the end frame offset, based on if PTZ is present or not
    //-------------------------------------------------------------------
    if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
    {
        endFrame.size.height += 75;
        endFrame.size.width -= fullScreenView.ptzImageOffset;

        if (!fullScreenView.hasPTZ)
        {
            endFrame.origin.x += 128;
            endFrame.size.width = [UIScreen mainScreen].bounds.size.height;
        }
    }
    else
    {
        endFrame.size.height -= fullScreenView.ptzImageOffset;
    }

    self.transitioningImageView = [[UIImageView alloc] initWithFrame:originalFrame];
    self.transitioningImageView.image = self.cellImageView.image;
    self.transitioningImageView.contentMode = UIViewContentModeScaleAspectFit;

    if (fullScreenView.imageView.image)
    {
        self.transitioningImageView.image = fullScreenView.imageView.image;
        self.cellImageView.image = fullScreenView.imageView.image;
    }

    //-------------------------------------------------------------------
    // Handle the presenting animation
    //-------------------------------------------------------------------
    if (self.presenting)
    {
        fromViewController.view.userInteractionEnabled = NO;

        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView sav_addFlushConstraintsForView:toViewController.view];
        toViewController.view.alpha = 0;
        [transitionContext.containerView addSubview:self.transitioningImageView];

        self.cellImageView.hidden = YES;

        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            self.transitioningImageView.frame = endFrame;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self.transitioningImageView removeFromSuperview];

            fullScreenView.imageView.image = self.cellImageView.image;
            fullScreenView.imageView.hidden = NO;

            [transitionContext completeTransition:YES];
        }];
    }
    //-------------------------------------------------------------------
    // Handle the teardown animation
    //-------------------------------------------------------------------
    else
    {
        toViewController.view.userInteractionEnabled = YES;

        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:self.transitioningImageView];
        self.transitioningImageView.frame = endFrame;

        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            self.transitioningImageView.frame = originalFrame;
            fromViewController.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self.transitioningImageView removeFromSuperview];
            self.cellImageView.hidden = NO;

            [transitionContext completeTransition:YES];
            [[[UIApplication sharedApplication] keyWindow] addSubview:toViewController.view];
        }];

    }
}

@end
