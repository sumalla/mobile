//
//  SCUSchedulingTempModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import <SavantControl/SAVClimateSchedule.h>
#import "SCUSchedulingEditingModel.h"

typedef NS_ENUM(NSInteger, SCUSchedulingDayCellType)
{
    SCUSchedulingDayCellType_AllYear,
    SCUSchedulingDayCellType_Date,
};

@interface SCUSchedulingTempModel : SCUSchedulingEditingModel

@property (nonatomic) NSArray *setPoints;
@property (nonatomic, readonly) CGFloat range, minPoint, maxPoint, buffer;
@property (nonatomic) NSArray *possibleModes;
@property (nonatomic) BOOL modePresent;
@property (nonatomic, getter=isHumidityModel, readonly) BOOL humidityModel;

- (NSUInteger)setTime:(NSDate *)time forRow:(NSUInteger)row;
- (void)setModeAtIndex:(NSInteger)index;
- (NSString *)nameForScheduleMode:(SAVClimateScheduleMode)mode;
- (NSDate *)timeForRow:(NSUInteger)row;
- (SAVClimateSetPoint *)setPointForRow:(NSUInteger)row;
- (NSArray *)getPossibleModes;

@end
