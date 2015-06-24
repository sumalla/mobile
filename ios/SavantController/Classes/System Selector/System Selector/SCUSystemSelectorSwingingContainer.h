//
//  SCUSystemSelectorSwingingContainer.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwingingViewController.h"
#import "SCUMainViewController.h"
#import "SCUThemedNavigationViewController.h"

@interface SCUSystemSelectorSwingingContainer : SCUSwingingViewController

- (instancetype)initWithFromLocation:(SCUSystemSelectorFromLocation)fromLocation;

@property (nonatomic, readonly) SCUThemedNavigationViewController *navController;

@end
