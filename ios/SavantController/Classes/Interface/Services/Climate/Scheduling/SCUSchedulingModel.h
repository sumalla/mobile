//
//  SCUSchedulingModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHVACPickerModel.h"
#import "SCUDataSourceModel.h"

@class SAVDISRequest, SAVClimateSchedule, SAVService;

@protocol SCUClimateSchedulingModelDelegate;

typedef NS_ENUM(NSInteger, SCUScheduleTableType)
{
    SCUScheduleTableType_Active,
    SCUScheduleTableType_AllSchedules
};

typedef NS_ENUM(NSInteger, SCUScheduleCellType)
{
    SCUScheduleCellType_Toggle  = 0,
    SCUScheduleCellType_Default = 1
};

@interface SCUSchedulingModel : SCUDataSourceModel <SCUHVACPickerModelViewSchedulingDelegate>

- (instancetype)initWithService:(SAVService *)service;

- (void)listenToSwitch:(UISwitch *)toggleSwitch atIndexPath:(NSIndexPath *)indexPath;

- (void)addDelegate:(id <SCUClimateSchedulingModelDelegate>)delegate;
- (void)removeDelegate:(id <SCUClimateSchedulingModelDelegate>)delegate;

- (void)removeScheduleAtIndexPath:(NSIndexPath *)indexPath;
- (void)saveSchedule:(SAVClimateSchedule *)schedule;

@property SCUScheduleTableType type;
@property (nonatomic, readonly) NSString *zoneName;
@property (readonly) NSString *assignedProfile;
@property (readonly) NSMutableDictionary *schedules;
@property (readonly) NSDictionary *schedulerSettings;

@end

@protocol SCUClimateSchedulingModelDelegate <NSObject>

@optional
- (void)assignedScheduleChanged:(NSString *)assignedSchedule;
- (void)reloadData;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)viewAllSchedules;
- (void)editSchedule:(SAVClimateSchedule *)schedule;
- (void)newSchedule:(NSDictionary *)settings;

@end
