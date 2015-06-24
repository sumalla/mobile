//
//  SCUMediaServiceViewControllerPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaServiceViewController.h"
@import Extensions;
#import "SCUMediaRequestViewControllerModel.h"

@interface SCUMediaServiceViewController () <SCUMediaRequestViewControllerModelDelegate>

@property (nonatomic) UINavigationController *navController;
@property (nonatomic) UINavigationController *modalNavigationController;
@property (nonatomic, readonly, getter = isScene) BOOL scene;
@property (nonatomic) SCUMediaRequestViewControllerModel *mediaModel;
@property (nonatomic) UIView *headerView;

- (void)reachedLeaf;

@end
