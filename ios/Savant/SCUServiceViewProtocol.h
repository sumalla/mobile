//
//  SCUServiceViewProtocol.h
//  SavantController
//
//  Created by Nathan Trapp on 10/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"
#import "SCUGradientView.h"
#import "SCUServiceViewProtocol.h"

@class SCUToolbar;

@protocol SCUServiceViewProtocol

@property (nonatomic) SCUServiceViewModel *model;
@property (nonatomic, readonly) SAVService *service;
@property (nonatomic, readonly) SAVServiceGroup *serviceGroup;

@property (nonatomic, weak) UIPanGestureRecognizer *panGesture;
@property (nonatomic, copy) dispatch_block_t dismissalCompletionBlock;

- (instancetype)initWithService:(SAVService *)service;
- (void)powerOff:(UIBarButtonItem *)sender;

@end
