//
//  UIViewController+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIViewController+SAVExtensions.h"
#import "UIDevice+SAVExtensions.h"
@import ObjectiveC.runtime;

@implementation UIViewController (SAVExtensions)

- (void)setSav_dismissalBlock:(dispatch_block_t)sav_dismissalBlock
{
    objc_setAssociatedObject(self, @selector(sav_dismissalBlock), sav_dismissalBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (dispatch_block_t)sav_dismissalBlock
{
    return objc_getAssociatedObject(self, @selector(sav_dismissalBlock));
}

- (void)sav_dismiss
{
    if (self.sav_dismissalBlock)
    {
        self.sav_dismissalBlock();
    }
}

- (void)sav_addChildViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    [viewController didMoveToParentViewController:self];
    [self.view addSubview:viewController.view];
}

- (void)sav_removeFromParentViewController
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (BOOL)sav_notifyWhenNavigatedBack:(void (^)())block
{
    BOOL success = NO;

    if (block)
    {
        success = YES;

        if (self.navigationController.interactivePopGestureRecognizer.state == UIGestureRecognizerStateBegan)
        {
            success = [self sav_notifyWhenInteractiveGestureCompleted:^(BOOL cancelled) {
                if (!cancelled)
                {
                    block();
                }
            }];
        }
        else
        {
            block();
        }
    }

    return success;
}

- (BOOL)sav_notifyWhenInteractiveGestureCompleted:(SAVInteractiveCompletionBlock)block
{
    BOOL success = NO;

    if (self.transitionCoordinator && block)
    {
        success = YES;

        [self.transitionCoordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            if ([context isCancelled])
            {
                block(YES);
            }
            else
            {
                block(NO);
            }
        }];
    }

    return success;
}

- (void)sav_updateTitle:(NSString *)title
{
    self.title = title;
    self.parentViewController.title = title;
}

- (id)debugQuickLookObject
{
    return self.view;
}

- (void)animateInterfaceRotationChangeWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator block:(void (^)(UIInterfaceOrientation orientation))block
{
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;

    if ([coordinator targetTransform].b > 0)
    {
        switch ([UIDevice interfaceOrientation])
        {
            case UIInterfaceOrientationUnknown:
                orientation = UIInterfaceOrientationUnknown;
                break;
            case UIInterfaceOrientationPortrait:
                orientation = UIInterfaceOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientation = UIInterfaceOrientationLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientation = UIInterfaceOrientationPortrait;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientation = UIInterfaceOrientationPortraitUpsideDown;
                break;
        }
    }
    else if (fabs([coordinator targetTransform].b) == 0)
    {
        switch ([UIDevice interfaceOrientation])
        {
            case UIInterfaceOrientationUnknown:
                orientation = UIInterfaceOrientationUnknown;
                break;
            case UIInterfaceOrientationPortrait:
                orientation = UIInterfaceOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientation = UIInterfaceOrientationPortrait;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientation = UIInterfaceOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientation = UIInterfaceOrientationLandscapeLeft;
                break;
        }
    }
    else
    {
        switch ([UIDevice interfaceOrientation])
        {
            case UIInterfaceOrientationUnknown:
                orientation = UIInterfaceOrientationUnknown;
                break;
            case UIInterfaceOrientationPortrait:
                orientation = UIInterfaceOrientationLandscapeLeft;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientation = UIInterfaceOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientation = UIInterfaceOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientation = UIInterfaceOrientationPortrait;
                break;
        }
    }

    [UIView animateWithDuration:[coordinator transitionDuration] animations:^{
        block(orientation);
    }];
}

@end
