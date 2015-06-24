//
//  SCUCameraFullScreenViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewController.h"

@class SAVCameraEntity;

@interface SCUCameraFullScreenViewController : SCUServiceViewController

- (instancetype)initWithCameraEntity:(SAVCameraEntity *)entity;

@property (nonatomic, readonly) NSUInteger ptzImageOffset;

@property (nonatomic, readonly) BOOL hasPTZ;
@property (readonly) SAVCameraEntity *entity;
@property (readonly) UIImageView *imageView;

@end
