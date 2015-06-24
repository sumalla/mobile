//
//  SCUSchedulingHumidityViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingHumidityViewController.h"
#import "SCUSchedulingHumidityModel.h"

@interface SCUSchedulingHumidityViewController ()

@property SCUSchedulingHumidityModel *model;

@end

@implementation SCUSchedulingHumidityViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSchedulingHumidityModel alloc] initWithSchedule:schedule];
        self.model.delegate = self;
    }
    return self;
}

@end
