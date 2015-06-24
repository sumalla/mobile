//
//  SCUSchedulingDayModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditingModel.h"

@class SAVClimateSchedule;

typedef NS_ENUM(NSInteger, SCUSchedulingDayCellType)
{
    SCUSchedulingDayCellType_AllYear,
    SCUSchedulingDayCellType_Date,
    SCUSchedulingDayCellType_Days,
    SCUSchedulingDayCellType_Picker,
    SCUSchedulingDayCellType_DayPicker
};

typedef NS_ENUM(NSInteger, SCUSchedulingDayType)
{
    SCUSchedulingDayType_Start,
    SCUSchedulingDayType_End
};

@interface SCUSchedulingDayModel : SCUSchedulingEditingModel

@property (nonatomic) NSDate *startDate, *endDate;
@property (nonatomic) NSIndexPath *pickerIndexPath;

@end
