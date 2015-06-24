//
//  SCUAVSettingsModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsModel.h"

@interface SCUAVSettingsModel ()

@property (nonatomic) NSArray *dataSource;

@property (nonatomic) SCUAVSettingsModelType type;

@property (nonatomic) NSString *serviceID;

- (void)presentNextModel:(SCUAVSettingsModel *)nextModel;

@end
