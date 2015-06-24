//
//  SCUHomeCellPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 6/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeCell.h"
#import "SCUButton.h"
#import "SCUGradientView.h"
#import <SavantControl/SavantControl.h>

@interface SCUHomeCell ()

@property SCUButton2 *serviceButton;
@property SCUButton2 *lightsButton;
@property SCUButton2 *fanButton;
@property SCUButton2 *temperatureButton;
@property SCUButton2 *securityButton;
@property NSArray *indicators;
@property UILongPressGestureRecognizer *longPressGestureRecognizer;
@property UIImageView *backgroundImage;
@property SCUGradientView *gradient;

- (void)distributeIndicators;
- (void)updateActiveService;
- (void)updateLightsAreOn;
- (void)updateFansAreOn;
- (void)updateCurrentTemperature;
- (void)updateSecurityAlert;

@property (nonatomic, readonly) NSInteger indicatorSpacing;
@property (nonatomic, readonly) CGFloat shadowRadius;

@end