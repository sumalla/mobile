//
//  SCUSignInTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUSignInViewModel.h"

@interface SCUSignInTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUSignInViewModel *)model;

@property (nonatomic, getter = isInNavigationController) BOOL inNavigationController;

@property (nonatomic) BOOL forceCancel;

@end
