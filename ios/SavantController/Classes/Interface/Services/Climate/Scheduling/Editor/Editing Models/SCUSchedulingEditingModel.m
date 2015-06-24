//
//  SCUSchedulingEditingModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditingModel.h"
#import "SCUInterface.h"
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingEditingModel ()

@property SAVClimateSchedule *schedule;

@end

@implementation SCUSchedulingEditingModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.schedule = schedule;
        
        if (!self.schedule.zones.count)
        {
            NSArray *zoneData = [[SavantControl sharedControl].data HVACZonesInRooms];
            NSMutableArray *zones = [NSMutableArray array];
            for (NSDictionary *zone in zoneData)
            {
                SAVRoom *currentRoom = [SCUInterface sharedInstance].currentRoom;
                if ([zone[@"rooms"] containsObject:currentRoom.roomId])
                {
                    [zones addObject:zone[@"zoneName"]];
                }
            }
            self.schedule.zones = zones;
        }
    }
    return self;
}

@end
