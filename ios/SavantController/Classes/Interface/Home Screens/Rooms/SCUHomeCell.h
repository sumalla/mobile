//
//  SCUHomeCell.h
//  SavantController
//
//  Created by Nathan Trapp on 6/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultCollectionViewCell.h"

@class SCUButton2, SAVService;

@interface SCUHomeCell : SCUDefaultCollectionViewCell

@property (nonatomic) SAVService *activeService;
@property (nonatomic) NSString *currentTemperature;
@property (nonatomic) BOOL     lightsAreOn;
@property (nonatomic) BOOL     fansAreOn;
@property (nonatomic) BOOL     hasSecurityAlert;

@property (readonly) SCUButton2 *serviceButton;
@property (readonly) SCUButton2 *lightsButton;
@property (readonly) SCUButton2 *fanButton;
@property (readonly) SCUButton2 *temperatureButton;
@property (readonly) SCUButton2 *securityButton;

@property (nonatomic, getter = isDisplayingDefaultImage) BOOL displayingDefaultImage;
@property (readonly) UIImageView *backgroundImage;

@property (readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;

- (void)endUpdates;

@end
