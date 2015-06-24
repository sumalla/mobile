//
//  UINavigationController+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@protocol SAVNavigationControllerDelegate <UINavigationControllerDelegate>

@optional

- (void)navigationController:(UINavigationController *)navigationController willPopToViewController:(UIViewController *)viewController;

@end

@interface UINavigationController (SAVExtensions)

- (void)addDelegate:(id<SAVNavigationControllerDelegate>)delegate;

- (void)removeDelegate:(id<SAVNavigationControllerDelegate>)delegate;

@property (nonatomic) NSNumber *sav_viewControllersCount;

@end
