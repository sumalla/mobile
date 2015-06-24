//
//  UIViewController+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIViewController (SAVExtensions)

typedef void (^SAVInteractiveCompletionBlock)(BOOL cancelled);

typedef void (^SAVInteractiveCompletionBlock)(BOOL navigated);

@property (nonatomic, copy) dispatch_block_t sav_dismissalBlock;

- (void)sav_dismiss;

- (void)sav_addChildViewController:(UIViewController *)viewController;
- (void)sav_removeFromParentViewController;
- (BOOL)sav_notifyWhenNavigatedBack:(void (^)())block;
- (BOOL)sav_notifyWhenInteractiveGestureCompleted:(SAVInteractiveCompletionBlock)block;

- (void)sav_updateTitle:(NSString *)title;

- (void)animateInterfaceRotationChangeWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator block:(void (^)(UIInterfaceOrientation orientation))block;

@end
