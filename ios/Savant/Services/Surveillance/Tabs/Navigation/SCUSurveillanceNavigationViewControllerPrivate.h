//
//  SCUSurveillanceNavigationViewControllerPrivate.h
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumberPadViewController.h"
#import "SCUDynamicButtonsCollectionViewController.h"
#import "SCUButtonViewController.h"
#import "SCUButton.h"

@interface SCUSurveillanceNavigationViewController ()

@property (nonatomic) SCUSwipeView *directionalSwipeView;

@property (nonatomic) SCUDynamicButtonsCollectionViewController *dynamicButtons;
@property (nonatomic) SCUButtonViewController *transportContainer;
@property (nonatomic) SCUButtonViewController *numberPad;
@property (nonatomic) SCUButton *exitButton;

@end