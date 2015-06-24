//
//  SCUPassthroughSupplementaryViewControllerPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPassthroughSupplementaryViewController.h"

@protocol SCUPassthroughSupplementaryViewControllerVisibilityDelegate <NSObject>

- (void)showSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController;

- (void)hideSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController;

@end

@interface SCUPassthroughSupplementaryViewController ()

@property (nonatomic, weak) id<SCUPassthroughSupplementaryViewControllerVisibilityDelegate> visibilityDelegate;

@end
