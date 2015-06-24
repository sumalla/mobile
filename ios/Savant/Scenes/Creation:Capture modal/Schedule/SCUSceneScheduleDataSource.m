//
//  SCUSceneScheduleDataSource.m
//  SavantController
//
//  Created by Nathan Trapp on 8/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneScheduleDataSource.h"
#import "SCUSceneCreationDataSourcePrivate.h"
#import "SCUDayPickerCell.h"
#import "SCUDatePickerCell.h"
#import "SCUDateCell.h"
#import "SCUSecondsPickerCell.h"
#import "SCUSecondsPickerView.h"
#import "SCUToggleSwitchTableViewCell.h"

#import <PMEDatePicker/PMEDatePicker.h>
@import Extensions;

static NSString *const SCUSceneCellTypeKey = @"SCUSceneCellTypeKey";
static NSString *const SCUSceneScheduleTypeKey = @"SCUSceneScheduleTypeKey";

@interface SCUSceneScheduleDataSource ()

@end

@implementation SCUSceneScheduleDataSource

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        self.scene.scheduled = YES;

        if (!self.scene.startDate)
        {
            self.scene.startDate = [NSDate today];
        }

        if (!self.scene.endDate)
        {
            self.scene.endDate = [NSDate today];
        }

        if (![self.scene.days count])
        {
            self.scene.days = [@[@0, @1, @2, @3, @4, @5, @6] mutableCopy];
        }

        [self prepareData];
    }
    return self;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate toggleIndex:indexPath];
}

- (void)selectChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        SAVSceneScheduleType type = [[self modelObjectForChild:child belowIndexPath:indexPath][SCUSceneScheduleTypeKey] integerValue];

        if (self.scene.scheduleType != type)
        {
            self.scene.scheduleType = type;
            self.scene.time = 0;

            [self prepareData];

            [self.delegate reloadData];
        }
    }
    else if (indexPath.row == 1 && self.scene.scheduleType == SAVSceneScheduleType_Celestial)
    {
        SAVSceneCelestialType type = [[self modelObjectForChild:child belowIndexPath:indexPath][SCUSceneScheduleTypeKey] integerValue];

        if (self.scene.celestialReference != type)
        {
            self.scene.celestialReference = type;

            [self prepareData];

            [self.delegate reloadData];
        }
    }
}

- (void)configureCell:(id)c withType:(NSUInteger)t forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneScheduleCellTypes type = t;
    switch (type)
    {
        case SCUSceneScheduleCellTypeDatePicker:
        {
            SCUDatePickerCell *cell = (SCUDatePickerCell *)c;

            [self listenToDatePicker:cell.datePicker withParent:indexPath];
        }
            break;

        case SCUSceneScheduleCellTypeDayPicker:
        {
            SCUDayPickerCell *cell = (SCUDayPickerCell *)c;

            [self listenToDayPicker:cell withParent:indexPath];
        }
            break;

        case SCUSceneScheduleCellTypeNumericPicker:
        {
            SCUSecondsPickerCell *cell = (SCUSecondsPickerCell *)c;

            [self listenToSecondsPicker:cell.pickerView withParent:indexPath];
        }
            break;

        default:
            break;
    }
}

- (void)prepareData
{
    NSMutableArray *dataSource = [NSMutableArray array];

    [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Type", nil),
                            SCUDefaultTableViewCellKeyDetailTitle: self.scene.scheduleTypeString,
                            SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                            SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDefault)}];

    switch (self.scene.scheduleType)
    {
        case SAVSceneScheduleType_Countdown:
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Time", nil),
                                    SCUDefaultTableViewCellKeyDetailTitle: [SCUSecondsPickerView stringForValue:self.scene.time],
                                    SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDefault),
                                    SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];

            break;
        case SAVSceneScheduleType_Celestial:
        case SAVSceneScheduleType_Normal:
            if (self.scene.scheduleType == SAVSceneScheduleType_Celestial)
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Celestial Reference", nil),
                                        SCUDefaultTableViewCellKeyDetailTitle: self.scene.celestialTypeString,
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                                        SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDefault)}];

                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Time Offset", nil),
                                        SCUDefaultTableViewCellKeyDetailTitle: [SCUSecondsPickerView stringForValue:self.scene.time],
                                        SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDefault),
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];
            }
            else
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Time", nil),
                                        SCUDateCellKeyDate: [NSDate dateWithTimeInterval:self.scene.time sinceDate:[NSDate today]],
                                        SCUDateCellKeyDateFormat: @"h:mm a",
                                        SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDate)}];
            }

            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"All Year", nil),
                                    SCUToggleSwitchTableViewCellKeyAnimate: @NO,
                                    SCUToggleSwitchTableViewCellKeyValue: @(self.scene.isAllYear),
                                    SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeToggle)}];

            if (!self.scene.isAllYear)
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Starts", nil),
                                        SCUDateCellKeyDate: self.scene.startDate,
                                        SCUDateCellKeyDateFormat: @"MMMM d",
                                        SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDate)}];

                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Ends", nil),
                                        SCUDateCellKeyDate: self.scene.endDate,
                                        SCUDateCellKeyDateFormat: @"MMMM d",
                                        SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDate)}];
            }

            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Days", nil),
                                    SCUDefaultTableViewCellKeyDetailTitle: [self.scene.days count] ? [self.scene dayString] : NSLocalizedString(@"Never", nil),
                                    SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                                    SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDefault)}];
            break;
    }

    self.dataSource = dataSource;
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = nil;

    if (indexPath.row == 0)
    {
        dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"At Time", nil),
                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.scheduleType == SAVSceneScheduleType_Normal ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                         SCUSceneScheduleTypeKey: @(SAVSceneScheduleType_Normal)},
                       @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Relative to Celestial Time", nil),
                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.scheduleType == SAVSceneScheduleType_Celestial ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                         SCUSceneScheduleTypeKey: @(SAVSceneScheduleType_Celestial)},
                       @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Countdown Timer", nil),
                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.scheduleType == SAVSceneScheduleType_Countdown ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                         SCUSceneScheduleTypeKey: @(SAVSceneScheduleType_Countdown)}];

        return dataSource;
    }

    switch (self.scene.scheduleType)
    {
        case SAVSceneScheduleType_Countdown:
        {
            if (indexPath.row == 1)
            {
                dataSource = @[@{SCUPickerCellKeyValue: @(self.scene.time),
                                 SCUPickerCellKeyValues: @[@0, @5, @15, @30, @60, @300, @600, @900, @1800, @2700, @3600, @7200, @18000],
                                 SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeNumericPicker)}];
            }
        }
            break;
        case SAVSceneScheduleType_Normal:
        case SAVSceneScheduleType_Celestial:
        {
            NSUInteger row = indexPath.row;
            if (self.scene.scheduleType == SAVSceneScheduleType_Celestial)
            {
                row--;
            }

            if (self.scene.isAllYear && row > 2)
            {
                row = row + 2;
            }

            switch (row)
            {
                case 0:
                    if (self.scene.scheduleType == SAVSceneScheduleType_Celestial)
                    {
                        dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dawn", nil),
                                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.celestialReference == SAVSceneCelestialType_Dawn ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                                         SCUSceneScheduleTypeKey: @(SAVSceneCelestialType_Dawn)},
                                       @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunrise", nil),
                                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.celestialReference == SAVSceneCelestialType_Sunrise ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                                         SCUSceneScheduleTypeKey: @(SAVSceneCelestialType_Sunrise)},
                                       @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunset", nil),
                                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.celestialReference == SAVSceneCelestialType_Sunset ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                                         SCUSceneScheduleTypeKey: @(SAVSceneCelestialType_Sunset)},
                                       @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dusk", nil),
                                         SCUDefaultTableViewCellKeyAccessoryType: @(self.scene.celestialReference == SAVSceneCelestialType_Dusk ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeChild),
                                         SCUSceneScheduleTypeKey: @(SAVSceneCelestialType_Dusk)}];
                    }
                    break;
                case 1:
                    if (self.scene.scheduleType == SAVSceneScheduleType_Celestial)
                    {
                        dataSource = @[@{SCUPickerCellKeyValue: @(self.scene.time),
                                         SCUPickerCellKeyValues: @[@(-18000), @(-7200), @(-3600), @(-2700), @(-900), @(-600), @(-300), @(-60),
                                                                   @0, @60, @300, @600, @900, @2700, @3600, @7200, @18000],
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeNumericPicker)}];
                    }
                    else
                    {
                        dataSource = @[@{SCUPickerCellKeySeconds: @(self.scene.time),
                                         SCUPickerCellKeyDateFormat: @"hmma",
                                         SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDatePicker)}];
                    }
                    break;
                case 3:
                    dataSource = @[@{SCUPickerCellKeyDate: self.scene.startDate ? self.scene.startDate : [NSDate today],
                                     SCUPickerCellKeyDateFormat: @"MMMM d",
                                     SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDatePicker)}];
                    break;
                case 4:
                    dataSource = @[@{SCUPickerCellKeyDate: self.scene.endDate ? self.scene.endDate : [NSDate today],
                                     SCUPickerCellKeyDateFormat: @"MMMM d",
                                     SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDatePicker)}];
                    break;
                case 5:
                {
                    SCUDayPickerDays selectedDays = SCUDayPickerDays_None;

                    for (NSNumber *day in self.scene.days)
                    {
                        SAVSceneScheduleDays buttonDay = [day integerValue];

                        switch (buttonDay)
                        {
                            case SAVSceneScheduleDay_Sunday:
                                selectedDays |= SCUDayPickerDays_Sunday;
                                break;
                            case SAVSceneScheduleDay_Monday:
                                selectedDays |= SCUDayPickerDays_Monday;
                                break;
                            case SAVSceneScheduleDay_Tuesday:
                                selectedDays |= SCUDayPickerDays_Tuesday;
                                break;
                            case SAVSceneScheduleDay_Wednesday:
                                selectedDays |= SCUDayPickerDays_Wednesday;
                                break;
                            case SAVSceneScheduleDay_Thursday:
                                selectedDays |= SCUDayPickerDays_Thursday;
                                break;
                            case SAVSceneScheduleDay_Friday:
                                selectedDays |= SCUDayPickerDays_Friday;
                                break;
                            case SAVSceneScheduleDay_Saturday:
                                selectedDays |= SCUDayPickerDays_Saturday;
                                break;
                        }
                    }

                    dataSource = @[@{SCUDayPickerCellKeySelectedDays: @(selectedDays),
                                     SCUDayPickerCellKeyAvailableDays: @(SCUDayPickerDays_All),
                                     SCUSceneCellTypeKey: @(SCUSceneScheduleCellTypeDayPicker)}];
                }
                    break;
            }
        }
            break;
    }
    
    return dataSource;
}

- (void)doneEditing
{
    if (self.scene.scheduleType != SAVSceneScheduleType_Countdown || self.scene.time)
    {
        self.scene.scheduled = YES;
    }
    else
    {
        self.scene.scheduled = NO;
    }
}

- (void)listenToSecondsPicker:(SCUSecondsPickerView *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.handler = ^(CGFloat value){
        wSelf.scene.time = value;

        [wSelf prepareData];

        [wSelf.delegate reloadIndexPath:indexPath];
    };
}

- (void)listenToDatePicker:(PMEDatePicker *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.handler = ^(NSDate *date, NSTimeInterval seconds){
        NSUInteger row = indexPath.row;
        if (self.scene.scheduleType == SAVSceneScheduleType_Celestial)
        {
            row--;
        }

        switch (row)
        {
            case 1:
            {
                wSelf.scene.time = seconds;
                break;
            }
            case 3:
                wSelf.scene.startDate = date;
                break;
            case 4:
                wSelf.scene.endDate = date;
                break;
        }

        [wSelf prepareData];

        switch (row)
        {
            case 1:
            {
                [wSelf.delegate reloadIndexPath:indexPath];
                break;
            }
            case 3:
            case 4:
                [wSelf.delegate reloadIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
                [wSelf.delegate reloadIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
                break;
        }
    };
}

- (void)listenToDayPicker:(SCUDayPickerCell *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.callback = ^(SCUDayPickerDays selectedDays){

        [wSelf.scene.days removeAllObjects];

        if (selectedDays & SCUDayPickerDays_Sunday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Sunday)];
        }

        if (selectedDays & SCUDayPickerDays_Monday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Monday)];
        }

        if (selectedDays & SCUDayPickerDays_Tuesday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Tuesday)];
        }

        if (selectedDays & SCUDayPickerDays_Wednesday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Wednesday)];
        }

        if (selectedDays & SCUDayPickerDays_Thursday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Thursday)];
        }

        if (selectedDays & SCUDayPickerDays_Friday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Friday)];
        }

        if (selectedDays & SCUDayPickerDays_Saturday)
        {
            [wSelf.scene.days addObject:@(SAVSceneScheduleDay_Saturday)];
        }

        [wSelf prepareData];

        [wSelf.delegate reloadIndexPath:indexPath];
    };
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForIndexPath:indexPath][SCUSceneCellTypeKey] integerValue];
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForChild:child belowIndexPath:indexPath][SCUSceneCellTypeKey] integerValue];
}

@end
