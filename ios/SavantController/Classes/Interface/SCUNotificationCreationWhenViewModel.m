//
//  SCUNotificationCreationWhenViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDatePickerCell.h"
#import "SCUDateCell.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUSecondsPickerView.h"
#import "SCUSecondsPickerCell.h"
#import "SCUDayPickerCell.h"
#import "SCUSchedulingPickerCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUNotificationCreationWhenViewModel.h"

#import <PMEDatePicker/PMEDatePicker.h>
#import <SavantControl/SAVNotification.h>

static NSString *const SCUNotificationCellTypeKey = @"SCUNotificationCellTypeKey";
static NSString *const SCUNotificationScheduleTypeKey = @"SCUNotificationScheduleTypeKey";
static NSString *const SCUNotificationCellPropertyKey = @"SCUNotificationCellPropertyKey";

@interface SCUNotificationCreationWhenViewModel ()

@property (nonatomic) NSArray *dataSource;

@end

@implementation SCUNotificationCreationWhenViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        if (!self.notification.startDate)
        {
            self.notification.startDate = [NSDate today];
        }
        if (!self.notification.endDate)
        {
            self.notification.endDate = [NSDate dateWithTimeInterval:86400 sinceDate:self.notification.startDate];
        }
        if (![self.notification.days count])
        {
            self.notification.days = [@[@0, @1, @2, @3, @4, @5, @6] mutableCopy];
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
        SAVNotificationScheduleType type = [[self modelObjectForChild:child belowIndexPath:indexPath][SCUNotificationScheduleTypeKey] integerValue];
        
        if (self.notification.scheduleType != type)
        {
            self.notification.scheduleType = type;
            self.notification.time = 0;
            
            [self prepareData];
            
            [self.delegate reloadData];
        }
    }
    else if (indexPath.row == 1 && self.notification.scheduleType == SAVNotificationScheduleType_Celestial)
    {
        SAVNotificationCelestialType type = [[self modelObjectForChild:child belowIndexPath:indexPath][SCUNotificationScheduleTypeKey] integerValue];
        
        if (self.notification.celestialReferenceStart != type)
        {
            self.notification.celestialReferenceStart = type;
            
            [self prepareData];
            
            [self.delegate reloadData];
        }
    }
    else if (indexPath.row == 3 && self.notification.scheduleType == SAVNotificationScheduleType_Celestial)
    {
        SAVNotificationCelestialType type = [[self modelObjectForChild:child belowIndexPath:indexPath][SCUNotificationScheduleTypeKey] integerValue];
        
        if (self.notification.celestialReferenceEnd != type)
        {
            self.notification.celestialReferenceEnd = type;
            
            [self prepareData];
            
            [self.delegate reloadData];
        }
    }
}

- (void)configureCell:(id)c withType:(NSUInteger)t forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUNotificationWhenCellType type = t;
    switch (type)
    {
        case SCUNotificationWhenCellTypeDatePicker:
        {
            SCUDatePickerCell *cell = (SCUDatePickerCell *)c;
            
            [self listenToDatePicker:cell.datePicker withParent:indexPath];
        }
            break;
            
        case SCUNotificationWhenCellTypeDayPicker:
        {
            SCUDayPickerCell *cell = (SCUDayPickerCell *)c;
            
            [self listenToDayPicker:cell withParent:indexPath];
        }
            break;
            
        case SCUNotificationWhenCellTypeNumericPicker:
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
                            SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyType),
                            SCUDefaultTableViewCellKeyDetailTitle: self.notification.scheduleTypeString,
                            SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                            SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault)}];
    
    switch (self.notification.scheduleType)
    {
        case SAVNotificationScheduleType_Celestial:
        case SAVNotificationScheduleType_Normal:
            if (self.notification.scheduleType == SAVNotificationScheduleType_Celestial)
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Start", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyCelestialStart),
                                        SCUDefaultTableViewCellKeyDetailTitle: self.notification.celestialTypeStringStart,
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault)}];
                
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Start Time Offset", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyCelestialStartOffset),
                                        SCUDefaultTableViewCellKeyDetailTitle: [SCUSecondsPickerView stringForValue:self.notification.startOffset],
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault),
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];
                
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"End", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyCelestialEnd),
                                        SCUDefaultTableViewCellKeyDetailTitle: self.notification.celestialTypeStringEnd,
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault)}];
                
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"End Time Offset", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyCelestialEndOffset),
                                        SCUDefaultTableViewCellKeyDetailTitle: [SCUSecondsPickerView stringForValue:self.notification.endOffset],
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault),
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];
            }
            else
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"All Day", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyAllDay),
                                        SCUToggleSwitchTableViewCellKeyAnimate: @NO,
                                        SCUToggleSwitchTableViewCellKeyValue: @(self.notification.isAllDay),
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeToggle)}];
                
                if (!self.notification.isAllDay)
                {
                    [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Start", nil),
                                            SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyStartTime),
                                            SCUDateCellKeyDate: [NSDate dateWithTimeInterval:self.notification.time sinceDate:[NSDate today]],
                                            SCUDateCellKeyDateFormat: @"hh:mm a",
                                            SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDate)}];
                    
                    [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"End", nil),
                                            SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyEndTime),
                                            SCUDateCellKeyDate: [NSDate dateWithTimeInterval:self.notification.endTime sinceDate:[NSDate today]],
                                            SCUDateCellKeyDateFormat: @"hh:mm a",
                                            SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDate)}];
                }
            }
            
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"All Year", nil),
                                    SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyAllYear),
                                    SCUToggleSwitchTableViewCellKeyAnimate: @NO,
                                    SCUToggleSwitchTableViewCellKeyValue: @(self.notification.isAllYear),
                                    SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeToggle)}];
            
            if (!self.notification.isAllYear)
            {
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Starts", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyStartDate),
                                        SCUDateCellKeyDate: self.notification.startDate,
                                        SCUDateCellKeyDateFormat: @"MMMM d",
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDate)}];
                
                [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Ends", nil),
                                        SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyEndDate),
                                        SCUDateCellKeyDate: self.notification.endDate,
                                        SCUDateCellKeyDateFormat: @"MMMM d",
                                        SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDate)}];
            }
            
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Days", nil),
                                    SCUNotificationCellPropertyKey: @(SCUNotificationWhenCellPropertyDays),
                                    SCUDefaultTableViewCellKeyDetailTitle: [self.notification.days count] ? [self.notification dayString] : NSLocalizedString(@"Never", nil),
                                    SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                                    SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDefault)}];
            break;
    }
    
    self.dataSource = dataSource;
}

- (SCUNotificationWhenCellProperty)cellPropertyForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    return [modelObject[SCUNotificationCellPropertyKey] integerValue];
}

- (NSIndexPath *)indexPathForProperty:(SCUNotificationWhenCellProperty)property
{
    NSInteger row = 0;
    for (NSDictionary *model in self.dataSource)
    {
        if ([model[SCUNotificationCellPropertyKey] integerValue] == property)
        {
            return [NSIndexPath indexPathForRow:row inSection:0];
        }
        row++;
    }
    
    return nil;
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = nil;
    
    SCUNotificationWhenCellProperty property = [self cellPropertyForIndexPath:indexPath];
    
    switch (property)
    {
        case SCUNotificationWhenCellPropertyType:
        {
            dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"At Time", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.scheduleType == SAVNotificationScheduleType_Normal ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationScheduleType_Normal)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Relative to Celestial Time", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.scheduleType == SAVNotificationScheduleType_Celestial ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationScheduleType_Celestial)}];
            
            return dataSource;
        }
        case SCUNotificationWhenCellPropertyCelestialStart:
        {
            dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dawn", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceStart == SAVNotificationCelestialType_Dawn ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Dawn)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunrise", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceStart == SAVNotificationCelestialType_Sunrise ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Sunrise)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunset", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceStart == SAVNotificationCelestialType_Sunset ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Sunset)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dusk", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceStart == SAVNotificationCelestialType_Dusk ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Dusk)}];
            break;
        }
        case SCUNotificationWhenCellPropertyCelestialEnd:
        {
            dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dawn", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceEnd == SAVNotificationCelestialType_Dawn ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Dawn)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunrise", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceEnd == SAVNotificationCelestialType_Sunrise ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Sunrise)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sunset", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceEnd == SAVNotificationCelestialType_Sunset ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Sunset)},
                           @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dusk", nil),
                             SCUDefaultTableViewCellKeyAccessoryType: @(self.notification.celestialReferenceEnd == SAVNotificationCelestialType_Dusk ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeChild),
                             SCUNotificationScheduleTypeKey: @(SAVNotificationCelestialType_Dusk)}];
            break;
        }
        case SCUNotificationWhenCellPropertyCelestialStartOffset:
        {
            dataSource = @[@{SCUPickerCellKeyValue: @(self.notification.startOffset),
                             SCUPickerCellKeyValues: @[@(-18000), @(-7200), @(-3600), @(-2700), @(-900), @(-600), @(-300), @(-60),
                                                       @0, @60, @300, @600, @900, @2700, @3600, @7200, @18000],
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeNumericPicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyCelestialEndOffset:
        {
            dataSource = @[@{SCUPickerCellKeyValue: @(self.notification.endOffset),
                             SCUPickerCellKeyValues: @[@(-18000), @(-7200), @(-3600), @(-2700), @(-900), @(-600), @(-300), @(-60),
                                                       @0, @60, @300, @600, @900, @2700, @3600, @7200, @18000],
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeNumericPicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyStartTime:
        {
            dataSource = @[@{SCUPickerCellKeyDate: [NSDate dateWithTimeInterval:self.notification.time sinceDate:[NSDate today]],
                             SCUPickerCellKeyDateFormat: @"hhmma",
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDatePicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyEndTime:
        {
            dataSource = @[@{SCUPickerCellKeyDate: [NSDate dateWithTimeInterval:self.notification.endTime sinceDate:[NSDate today]],
                             SCUPickerCellKeyDateFormat: @"hhmma",
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDatePicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyStartDate:
        {
            dataSource = @[@{SCUPickerCellKeyDate: self.notification.startDate,
                             SCUPickerCellKeyDateFormat: @"MMMM d",
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDatePicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyEndDate:
        {
            dataSource = @[@{SCUPickerCellKeyDate: self.notification.endDate,
                             SCUPickerCellKeyDateFormat: @"MMMM d",
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDatePicker)}];
            break;
        }
        case SCUNotificationWhenCellPropertyDays:
        {
            SCUDayPickerDays selectedDays = SCUDayPickerDays_None;
            
            for (NSNumber *day in self.notification.days)
            {
                
                SAVNotificationScheduleDays buttonDay = [day intValue];
                
                switch (buttonDay)
                {
                    case SAVNotificationScheduleDay_Sunday:
                        selectedDays |= SCUDayPickerDays_Sunday;
                        break;
                    case SAVNotificationScheduleDay_Monday:
                        selectedDays |= SCUDayPickerDays_Monday;
                        break;
                    case SAVNotificationScheduleDay_Tuesday:
                        selectedDays |= SCUDayPickerDays_Tuesday;
                        break;
                    case SAVNotificationScheduleDay_Wednesday:
                        selectedDays |= SCUDayPickerDays_Wednesday;
                        break;
                    case SAVNotificationScheduleDay_Thursday:
                        selectedDays |= SCUDayPickerDays_Thursday;
                        break;
                    case SAVNotificationScheduleDay_Friday:
                        selectedDays |= SCUDayPickerDays_Friday;
                        break;
                    case SAVNotificationScheduleDay_Saturday:
                        selectedDays |= SCUDayPickerDays_Saturday;
                        break;
                }
            }
            
            dataSource = @[@{SCUDayPickerCellKeySelectedDays: @(selectedDays),
                             SCUDayPickerCellKeyAvailableDays: @(SCUDayPickerDays_All),
                             SCUNotificationCellTypeKey: @(SCUNotificationWhenCellTypeDayPicker)}];
            break;
        }
    }
    
    return dataSource;
}

- (void)listenToSecondsPicker:(SCUSecondsPickerView *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.handler = ^(CGFloat value) {
        SAVStrongWeakSelf;
        SCUNotificationWhenCellProperty property = [self cellPropertyForIndexPath:indexPath];
        
        if (property == SCUNotificationWhenCellPropertyCelestialStartOffset)
        {
            sSelf.notification.startOffset = value;
        }
        else if (property == SCUNotificationWhenCellPropertyCelestialEndOffset)
        {
             sSelf.notification.endOffset = value;
        }
        
        [sSelf prepareData];
        
        [sSelf.delegate reloadIndexPath:indexPath];
    };
}

- (void)listenToDatePicker:(PMEDatePicker *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.handler = ^(NSDate *date, NSTimeInterval seconds){
        SAVStrongWeakSelf;
        SCUNotificationWhenCellProperty property = [self cellPropertyForIndexPath:indexPath];
        
        switch (property)
        {
            case SCUNotificationWhenCellPropertyStartTime:
            {
                sSelf.notification.time = seconds;
                break;
            }
            case SCUNotificationWhenCellPropertyEndTime:
                sSelf.notification.endTime = seconds;
                break;
            case SCUNotificationWhenCellPropertyStartDate:
                sSelf.notification.startDate = date;
                break;
            case SCUNotificationWhenCellPropertyEndDate:
                sSelf.notification.endDate = date;
                break;
        }
        
        [wSelf prepareData];
        
        switch (property)
        {
            case SCUNotificationWhenCellPropertyStartTime:
            case SCUNotificationWhenCellPropertyEndTime:
                [sSelf.delegate reloadIndexPath:indexPath];
                break;
                
            case SCUNotificationWhenCellPropertyStartDate:
            case SCUNotificationWhenCellPropertyEndDate:
            {
                NSIndexPath *startIndexPath = [self indexPathForProperty:property];
                NSIndexPath *endIndexPath = [self indexPathForProperty:property];
                [sSelf.delegate reloadIndexPath:startIndexPath];
                [sSelf.delegate reloadIndexPath:endIndexPath];
                break;
            }
        }
    };
}

- (void)listenToDayPicker:(SCUDayPickerCell *)picker withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    picker.callback = ^(SCUDayPickerDays selectedDays){
        SAVStrongWeakSelf;
        [sSelf.notification.days removeAllObjects];
        
        if (selectedDays & SCUDayPickerDays_Sunday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Sunday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Monday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Monday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Tuesday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Tuesday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Wednesday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Wednesday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Thursday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Thursday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Friday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Friday)];
        }
        
        if (selectedDays & SCUDayPickerDays_Saturday)
        {
            [sSelf.notification.days addObject:@(SAVNotificationScheduleDay_Saturday)];
        }
        
        [sSelf prepareData];
        
        [sSelf.delegate reloadIndexPath:indexPath];
    };
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForIndexPath:indexPath][SCUNotificationCellTypeKey] integerValue];
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForChild:child belowIndexPath:indexPath][SCUNotificationCellTypeKey] integerValue];
}

@end
