//
//  SCUNowPlayingToolbar.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPassthroughSupplementaryViewController.h"

@class
SAVService,
SAVServiceGroup;

/**
 *  Don't use this class directly. Use one its concrete layout subclasses.
 */
@interface SCUNowPlayingViewController : SCUPassthroughSupplementaryViewController

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup;

@property (nonatomic, copy) dispatch_block_t artworkTappedBlock;
@property (nonatomic) BOOL showServicesFirstButton;

@property (readonly, nonatomic) SAVService *service;

@end
