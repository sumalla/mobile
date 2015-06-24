//
//  SCUGlobalNowPlayingNowPlayingViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingViewController.h"

@class SAVServiceGroup;

@interface SCUGlobalNowPlayingNowPlayingViewController : SCUNowPlayingViewController

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)serviceGroup;
+ (NSArray *)transportButtonsForServiceGroup:(SAVServiceGroup *)serviceGroup;

@property (nonatomic, readonly) NSArray *transportButtons;
@property (nonatomic, readonly) SAVServiceGroup *serviceGroup;

@end
