//
//  SCUSchedulingEditorModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

typedef NS_ENUM(NSInteger, SCUSchedulingEditorType)
{
    SCUSchedulingEditorType_Days,
    SCUSchedulingEditorType_Rooms,
    SCUSchedulingEditorType_Temp,
    SCUSchedulingEditorType_Humidity
};

@class SAVClimateSchedule;

@interface SCUSchedulingEditorModel : SCUDataSourceModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule;

@property (nonatomic) NSArray *selectedIndexPaths;
@property (readonly) SAVClimateSchedule *schedule;

@end
