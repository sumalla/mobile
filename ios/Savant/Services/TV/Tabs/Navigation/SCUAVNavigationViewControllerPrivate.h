//
//  SCUTVNavigationViewControllerPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumberPadViewController.h"
#import "SCUDynamicButtonsCollectionViewController.h"
#import "SCUButtonViewController.h"
#import "SCUCustomHoldButton.h"
#import "SCUPagedViewControl.h"

@interface SCUAVNavigationViewController () <UIScrollViewDelegate, SCUSwipeViewDelegate>

@property (nonatomic) UIView *statusView;
@property (nonatomic) UIView *bottomView;

@property (nonatomic) SCUPagedViewControl *bottomPagedView;

@property (nonatomic) UILabel *bottomLabel;
@property (nonatomic) NSArray *pickerDataSource;

@property (nonatomic) SCUButton *exitButton;
@property (nonatomic) SCUButton *lastButton;
@property (nonatomic) SCUButton *dvrButton;
@property (nonatomic) SCUButton *guideButton;

@property (nonatomic) SCUButton *upButton;
@property (nonatomic) SCUButton *downButton;

@property (nonatomic) SCUSwipeView *directionalSwipeView;

@property (nonatomic) SCUButtonViewController *transportContainer;
@property (nonatomic) SCUNumberPadViewController *numberPad;

@property (nonatomic) NSArray *landscapeScrollviewConstraints;
@property (nonatomic) NSArray *portraitScrollviewConstraints;

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *buttonContainer;

- (void)handlePressForUpButton;

- (void)handlePressForDownButton;

- (void)handleHoldForUpButton;

- (void)handleHoldForDownButton;

- (void)handleRelease;

@end
