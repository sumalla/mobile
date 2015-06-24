//
//  SCUAVNumberPadViewControllerPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 2/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUAVNumberPadViewController.h"
#import "SCUAVNavigationViewControllerPrivate.h"

@interface SCUAVNumberPadViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *container;
@property (nonatomic) UIView *handle;
@property (nonatomic) SCUAVNumberPadViewState currentState;

@end
