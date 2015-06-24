//
//  SCUSchedulingDayModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingDayModel.h"
#import "SCUDateCell.h"
#import "SCUDatePickerCell.h"
#import "SCUSchedulingToggleCell.h"
#import "SCUDayPickerCell.h"
#import <SavantControl/SAVClimateSchedule.h>

typedef NS_ENUM(NSInteger, SCUSchedulingDayRow)
{
    SCUSchedulingDayRow_AllYear,
    SCUSchedulingDayRow_StartDate,
    SCUSchedulingDayRow_EndDate,
    SCUSchedulingDayRow_DayPicker,
    SCUSchedulingDayRow_Picker,
    SCUSchedulingDayRow_Days,
    SCUSchedulingDayRow_Unknown = -1
};

@interface SCUSchedulingDayModel ()

@property SAVClimateSchedule *schedule;

@end

@implementation SCUSchedulingDayModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super initWithSchedule:schedule];
    if (self)
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yyyy hh:mm:ss";
        
        NSDate *endDate = [df dateFromString:self.schedule.dateRange[@"endDate"]];
        NSDate *startDate = [df dateFromString:self.schedule.dateRange[@"startDate"]];
        
        NSString *todayString     = [df stringFromDate:[NSDate today]];
        NSString *endDateString   = [df stringFromDate:endDate];
        NSString *startDateString = [df stringFromDate:startDate];

        _startDate = self.schedule.isAllYear ? [df dateFromString:todayString] : [df dateFromString:startDateString];
        _endDate = self.schedule.isAllYear ? [[df dateFromString:todayString] dateByAddingTimeInterval:60 * 60 * 24] : [df dateFromString:endDateString];
    }
    
    return self;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return self.pickerIndexPath ? (self.schedule.isAllYear ? 3 : 5) : (self.schedule.isAllYear ? 2 : 4);
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingDayRow type = [self typeForIndexPath:indexPath];

    NSDictionary *modelObject = nil;

    switch (type)
    {
        case SCUSchedulingDayRow_AllYear:
            modelObject = @{SCUToggleSwitchTableViewCellKeyValue: @(self.schedule.isAllYear),
                            SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"All Year", nil)};
            break;
        case SCUSchedulingDayRow_StartDate:
            modelObject = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Starts", nil),
                            SCUDateCellKeyDate: self.startDate,
                            SCUDateCellKeyDateFormat: @"MMMM d"};
            break;
        case SCUSchedulingDayRow_EndDate:
            modelObject = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Ends", nil),
                            SCUDateCellKeyDate: self.endDate,
                            SCUDateCellKeyDateFormat: @"MMMM d"};
            break;
        case SCUSchedulingDayRow_Picker:
        {
            SCUSchedulingDayType type = SCUSchedulingDayType_Start;
            NSDate *date = self.startDate;

            if ((indexPath.row - 1) == SCUSchedulingDayRow_EndDate)
            {
                type = SCUSchedulingDayType_End;
                date = self.endDate;
            }

            modelObject = @{SCUPickerCellKeyDate: date,
                            SCUPickerCellKeyDateType: @(type),
                            SCUPickerCellKeyDateFormat: @"MMMMd"};
        }
            break;
        case SCUSchedulingDayRow_DayPicker:
        {
            SCUDayPickerDays selectedDays = SCUDayPickerDays_None;

            for (NSNumber *day in self.schedule.days)
            {
                SAVClimateScheduleDay buttonDay = [day integerValue];

                switch (buttonDay)
                {
                    case SAVClimateScheduleDay_Sunday:
                        selectedDays |= SCUDayPickerDays_Sunday;
                        break;
                    case SAVClimateScheduleDay_Monday:
                        selectedDays |= SCUDayPickerDays_Monday;
                        break;
                    case SAVClimateScheduleDay_Tuesday:
                        selectedDays |= SCUDayPickerDays_Tuesday;
                        break;
                    case SAVClimateScheduleDay_Wednesday:
                        selectedDays |= SCUDayPickerDays_Wednesday;
                        break;
                    case SAVClimateScheduleDay_Thursday:
                        selectedDays |= SCUDayPickerDays_Thursday;
                        break;
                    case SAVClimateScheduleDay_Friday:
                        selectedDays |= SCUDayPickerDays_Friday;
                        break;
                    case SAVClimateScheduleDay_Saturday:
                        selectedDays |= SCUDayPickerDays_Saturday;
                        break;
                }
            }
            
            if (selectedDays == SCUDayPickerDays_None)
            {
                selectedDays = SCUDayPickerDays_All;
                self.schedule.days = @[@(SAVClimateScheduleDay_Sunday), @(SAVClimateScheduleDay_Monday), @(SAVClimateScheduleDay_Tuesday), @(SAVClimateScheduleDay_Wednesday), @(SAVClimateScheduleDay_Thursday), @(SAVClimateScheduleDay_Friday), @(SAVClimateScheduleDay_Saturday)];
            }

            modelObject = @{SCUDayPickerCellKeySelectedDays: @(selectedDays)};
        }
            break;
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingDayRow type = [self typeForIndexPath:indexPath];

    NSUInteger cellType = 0;

    switch (type)
    {
        case SCUSchedulingDayRow_AllYear:
            cellType = SCUSchedulingDayCellType_AllYear;
            break;
        case SCUSchedulingDayRow_StartDate:
        case SCUSchedulingDayRow_EndDate:
            cellType = SCUSchedulingDayCellType_Date;
            break;
        case SCUSchedulingDayRow_Picker:
            cellType = SCUSchedulingDayCellType_Picker;
            break;
        case SCUSchedulingDayRow_DayPicker:
            cellType = SCUSchedulingDayCellType_DayPicker;
            break;
    }

    return cellType;
}

- (SCUSchedulingDayRow)typeForIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingDayRow type = SCUSchedulingDayRow_Unknown;

    if (self.schedule.isAllYear)
    {
        switch (indexPath.row)
        {
            case 0:
            {
                type = SCUSchedulingDayRow_AllYear;
                break;
            }
            case 1:
            {
                type = SCUSchedulingDayRow_DayPicker;
                break;
            }
        }
    }
    else
    {
        if (self.pickerIndexPath)
        {
            type = indexPath.row;

            if (indexPath.row > self.pickerIndexPath.row)
            {
                type--;
            }
            else if ([indexPath isEqual:self.pickerIndexPath])
            {
                if ([self typeForIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0]] == SCUSchedulingDayRow_Days)
                {
                    type = SCUSchedulingDayRow_DayPicker;
                }
                else
                {
                    type = SCUSchedulingDayRow_Picker;
                }
            }
        }
        else
        {
            type = indexPath.row;
        }
    }

    return type;
}

- (void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;

    [self updateScheduleDates];
}

- (void)setEndDate:(NSDate *)endDate
{
    _endDate = endDate;

    [self updateScheduleDates];
}

- (void)updateScheduleDates
{
    if (!self.schedule.isAllYear)
    {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"MM/dd/yyyy hh:mm:ss";
    
            NSString *endDateString   = [df stringFromDate:self.endDate];
            NSString *startDateString = [df stringFromDate:self.startDate];

        self.schedule.dateRange = @{@"startDate": startDateString,
                                    @"endDate": endDateString};
    }
}

@end
