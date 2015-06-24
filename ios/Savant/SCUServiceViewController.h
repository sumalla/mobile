//
//  SCUServiceViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewProtocol.h"

@class SCUServiceTabBarController;

@interface SCUServiceViewController : UIViewController <SCUServiceViewProtocol>

@property (nonatomic) SCUServiceViewModel *model;

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation;

- (void)presentCustomView;

@property (nonatomic) NSArray *portraitConstraints;
@property (nonatomic) NSArray *landscapeConstraints;
@property (nonatomic) BOOL hasCustomPresentation;
@property (nonatomic, weak) SCUServiceTabBarController *serviceTabBarController;
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic) UIModalPresentationStyle customPresentationStyle;

@end
