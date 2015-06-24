//
//  SCUVolumeViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"
@class SAVRoom, SCUSlingshot, SAVServiceGroup, SAVService;

@interface SCUVolumeViewController : SCUModelViewController

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service;
- (instancetype)initWithService:(SAVService *)service;

@property (nonatomic) SAVServiceGroup *serviceGroup;
@property (nonatomic) SAVService *service;
@property (readonly) SCUSlingshot *volumeSlingshot;
@property (nonatomic) BOOL disallowGlobalRoomVolume;
@property (nonatomic, getter = isGlobalVolume) BOOL globalVolume;
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL isDiscrete;
@property (nonatomic) BOOL ignoreFirstAnimation;
@property (nonatomic) BOOL forceSlingshot;

@property (nonatomic, getter = isFullWidth) BOOL fullWidth;
@property (nonatomic, copy) dispatch_block_t sliderInteractionHandler;

@end