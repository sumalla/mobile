//
//  SCUNotificationAddRuleTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/22/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCURangeSlider.h"
#import "SCUNotificationAddRuleViewModel.h"
#import "SCUAlertView.h"

#import <SavantControl/SAVNotification.h>
#import <SavantControl/SAVNotificationManager.h>
#import <SavantControl.h>

@interface SCUNotificationAddRuleViewModel ()

@property (nonatomic) NSArray *dataSource;

@end

static NSString *SCUNotificationAddRuleViewModelKeySectionArray  = @"SCUNotificationAddServiceViewModelKeySectionArray";
static NSString *SCUNotificationAddRuleViewModelKeySectionTitle  = @"SCUNotificationAddServiceViewModelKeySectionTitle";
static NSString *SCUNotificationAddRuleViewModelKeyServiceToggle = @"SCUNotificationAddServiceViewModelKeyServiceToggle";
static NSString *SCUNotificationAddRuleViewModelKeyServiceType   = @"SCUNotificationAddRuleViewModelKeyServiceType";
static NSString *SCUNotificationAddServiceViewModelKeyRuleType   = @"SCUNotificationAddServiceViewModelKeyRuleType";

@implementation SCUNotificationAddRuleViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        [self prepareData];
    }
    
    return self;
}

- (void)prepareData
{
    NSArray *dataSource = @[@{SCUNotificationAddRuleViewModelKeySectionArray:
                                  @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Where", nil),
                                      SCUDefaultTableViewCellKeyDetailTitle: NSLocalizedString(@"Anywhere", nil),
                                      SCUNotificationAddRuleViewModelKeyServiceType: @(SCUNotificationsAddServiceRuleType_Where),
                                      SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                      SCUNotificationAddServiceViewModelKeyRuleType: @(SCUNotificationsAddServiceRuleType_Where)},
                                    @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"When", nil),
                                      SCUDefaultTableViewCellKeyDetailTitle: NSLocalizedString(@"Always", nil),
                                      SCUNotificationAddRuleViewModelKeyServiceType: @(SCUNotificationsAddServiceRuleType_When),
                                      SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                      SCUNotificationAddServiceViewModelKeyRuleType: @(SCUNotificationsAddServiceRuleType_When)}]},
                            @{SCUNotificationAddRuleViewModelKeySectionTitle: NSLocalizedString(@"Then...", nil),
                              SCUNotificationAddRuleViewModelKeySectionArray:
                                  @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Send", nil),
                                      SCUDefaultTableViewCellKeyDetailTitle: NSLocalizedString(@"None", nil),
                                      SCUNotificationAddRuleViewModelKeyServiceType: @(SCUNotificationsAddServiceRuleType_Send),
                                      SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                      SCUNotificationAddServiceViewModelKeyRuleType: @(SCUNotificationsAddServiceRuleType_Send)}]}];
    
    self.dataSource = [dataSource copy];
    
}

- (void)saveNotificationWithEditing:(BOOL)editing
{
    SAVWeakSelf;
    if (!editing)
    {
        [[SavantControl sharedControl].notificationManager registerNotification:self.notification
                                                              completionHandler:^(BOOL success, NSError *error) {
                                                                  if (!success)
                                                                  {
                                                                      SCUAlertView *alert = [[SCUAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription buttonTitles:@[@"Dismiss"]];
                                                                      [alert show];
                                                                  }
                                                                  else
                                                                  {
                                                                      [wSelf.delegate popToRootViewController];
                                                                  }
                                                              }];
    }
    else
    {
        [[SavantControl sharedControl].notificationManager updateTriggerForNotification:self.notification
                                                                      completionHandler:^(BOOL success, NSError *error) {
                                                                          [wSelf.delegate popToRootViewController];
                                                                    }];
    }
}

- (void)deleteNotification
{
    SAVWeakSelf;
    [[SavantControl sharedControl].notificationManager unregisterNotification:self.notification completionHandler:^(BOOL success, NSError *error) {
        if (!success)
        {
            SCUAlertView *alert = [[SCUAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription buttonTitles:@[@"Dismiss"]];
            [alert show];
        }
        else
        {
            [wSelf.delegate popToRootViewController];
        }
    }];
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUNotificationAddRuleViewModelKeySectionArray];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (self.dataSource[section][SCUNotificationAddRuleViewModelKeySectionTitle])
    {
        return self.dataSource[section][SCUNotificationAddRuleViewModelKeySectionTitle];
    }
    
    return @"";
}

- (NSString *)headerTextForType:(NSUInteger)type
{
    switch (type)
    {
        case SAVNotificationServiceTypeLighting:
            return [self.notification.triggerValues.firstObject boolValue] ? NSLocalizedString(@"If the lights are on...", nil) : NSLocalizedString(@"If the lights are off...", nil);
            
        case SAVNotificationServiceTypeEntertainment:
            return [self.notification.triggerValues.firstObject boolValue] ? NSLocalizedString(@"If A/V services are on...", nil) : NSLocalizedString(@"If A/V services are off...", nil);
    }
    
    return @"";
}

- (BOOL)displaysScheduleTime
{
    if (self.notification.isAllDay)
    {
        return NO;
    }
    
    if (self.notification.time == 0 && self.notification.endTime == 0)
    {
        return NO;
    }
    
    return YES;
}

- (NSString *)detailTextForServiceType:(SCUNotificationsAddServiceRuleType)type
{
    switch (type)
    {
        case SCUNotificationsAddServiceRuleType_When:
        {
            if ([self.notification isAllDay] && [self.notification isAllYear] && self.notification.days.count == 7)
            {
                return NSLocalizedString(@"Anytime", nil);
            }
            
            NSString *topString = @"";
            NSString *bottomString = @"";
            
            if (self.notification.scheduleType == SAVNotificationScheduleType_Celestial)
            {
                topString = [NSString stringWithFormat:@"%@ - %@, ", self.notification.celestialTypeStringStart, self.notification.celestialTypeStringEnd];
                topString = [topString stringByAppendingString:self.notification.dayString];
            }
            else if ([self displaysScheduleTime])
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"h:mma"];
                NSString *startString = [formatter stringFromDate:[NSDate dateWithTimeInterval:self.notification.time sinceDate:[NSDate today]]];
                NSString *endString = [formatter stringFromDate:[NSDate dateWithTimeInterval:self.notification.endTime sinceDate:[NSDate today]]];

                topString = [NSString stringWithFormat:@"%@ - %@", startString, endString];
            }
            
            if (self.notification.scheduleType == SAVNotificationScheduleType_Celestial)
            {
                bottomString = [NSString stringWithFormat:@"%@ to %@", self.notification.celestialTypeStringStart, self.notification.celestialTypeStringEnd];
                return [bottomString stringByAppendingString:self.notification.dayString];
            }
            else
            {
                NSString *dayString = self.notification.days.count ? self.notification.dayString : NSLocalizedString(@"Everyday", nil);
                if (self.notification.isAllYear)
                {
                    bottomString = [NSString stringWithFormat:@"%@, ", NSLocalizedString(@"All Year", nil)];
                }
                else
                {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"M/d"];
                    
                    NSString *startString = [formatter stringFromDate:self.notification.startDate];
                    NSString *endString = [formatter stringFromDate:self.notification.endDate];
                    
                    bottomString = [NSString stringWithFormat:@"%@ - %@, ", startString, endString];
                }
                
                bottomString = [bottomString stringByAppendingString:dayString];
            }
            
            if (topString.length && bottomString.length)
            {
                return [NSString stringWithFormat:@"%@\n%@", topString, bottomString];
            }
            else if (topString.length)
            {
                return topString;
            }
            else
            {
                return bottomString;
            }
            
        }
        case SCUNotificationsAddServiceRuleType_Where:
            if (self.notification.zones.count)
            {
                if (self.notification.zones.count == 1)
                {
                    return [self.notification.zones firstObject];
                }
                
                return [NSString stringWithFormat:@"%li zones", (long)self.notification.zones.count];
            }
            else if (self.notification.rooms.count)
            {
                if (self.notification.rooms.count == 1)
                {
                    return [self.notification.rooms firstObject];
                }
                
                return [NSString stringWithFormat:@"%li rooms", (long)self.notification.rooms.count];
            }
            else
            {
                return @"Anywhere";
            }
        case SCUNotificationsAddServiceRuleType_Send:
            if (self.notification.isEmailDeliveryEnabled && self.notification.isPushDeliveryEnabled)
            {
                return NSLocalizedString(@"Notification + Email", nil);
            }
            else if (self.notification.isEmailDeliveryEnabled)
            {
                return NSLocalizedString(@"Email", nil);
            }
            else if (self.notification.isPushDeliveryEnabled)
            {
                return NSLocalizedString(@"Notification", nil);
            }
            else
            {
                return NSLocalizedString(@"None", nil);
            }
    }
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForIndexPath:indexPath] mutableCopy];
    SCUNotificationsAddServiceRuleType type = [modelObject[SCUNotificationAddRuleViewModelKeyServiceType] integerValue];
    modelObject[SCUDefaultTableViewCellKeyDetailTitle] = [self detailTextForServiceType:type];
    
    return modelObject;
}

- (BOOL)isFlat
{
    return NO;
}

- (void)updateTriggerValuesWithSlider:(SCURangeSlider *)slider
{
    if ((self.notification.serviceType == SAVNotificationServiceTypeTemperature) || (self.notification.serviceType == SAVNotificationServiceTypeHumidity))
    {
        self.notification.triggerValues = [NSMutableArray arrayWithObjects:@(slider.leftValue), @(slider.rightValue), nil];
    }
}

- (SCUNotificationsAddServiceRuleType)ruleTypeForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    
    return [modelObject[SCUNotificationAddServiceViewModelKeyRuleType] integerValue];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    [self.notification applySettings:self.notification.dictionaryRepresentation];
}

@end
