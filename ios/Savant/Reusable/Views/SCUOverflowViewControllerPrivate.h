//
//  SCUOverflowViewControllerPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 2/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowViewController.h"

@class SCUButton;

@interface SCUOverflowViewController ()

@property (nonatomic) SCUButton *closeButton;

- (void)setupPad;

- (void)setupPhone;

@end