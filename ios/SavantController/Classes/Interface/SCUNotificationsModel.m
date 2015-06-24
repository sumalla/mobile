//
//  SCUNotificationsModel.m
//  SavantController
//
//  Created by Julian Locke on 1/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationsModel.h"
#import "SCUNotificationToggleTableViewCell.h"
#import "SCUNotificationInvisibleTableViewCell.h"
#import <SavantControl/SavantControl.h>
#import "SCUAlertView.h"
#import "SCUMainViewController.h"

#import <SavantControl/SavantControl.h>

#define ULTIMATE_ITEM (i + 1) == [array count]
#define PENULTIMATE_ITEM (i + 2) == [array count]

static NSString *SCUNotificationsModelObjectKeyType = @"SCUNotificationsModelObjectKeyType";
static NSString *SCUNotificationsModelObjectKeyCellType = @"SCUNotificationsModelObjectKeyCellType";

typedef NS_ENUM(NSUInteger, SCUNotificationModelType)
{
    SCUNotificationModelTypeNotification,
    SCUNotificationModelTypeStaticMessage,
};

@interface SCUNotificationsModel ()

@property (nonatomic) NSArray *dataSource;

@end

@implementation SCUNotificationsModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:nil];
    
    if (self)
    {
        [self loadData];
    }
    
    return self;
}

- (void)loadData
{
    __block NSMutableArray *data = [[NSMutableArray alloc] init];
    
    SAVWeakSelf;
    
    [[SavantControl sharedControl].notificationManager registeredNotificationsWithCompletionHandler:^(BOOL success, NSError *error, NSArray *payload) {
        SAVStrongWeakSelf;
        if (success)
        {
            for (SAVNotification *notification in payload)
            {
                NSString *title = @"";
                switch (notification.serviceType)
                {
                    case SAVNotificationServiceTypeHumidity:
                    case SAVNotificationServiceTypeTemperature:
                    {
                        title = NSLocalizedString(@"CLIMATE", nil);
                        break;
                    }
                    case SAVNotificationServiceTypeLighting:
                    {
                        title = NSLocalizedString(@"LIGHTING", nil);
                        break;
                    }
                    case SAVNotificationServiceTypeEntertainment:
                    {
                        title = NSLocalizedString(@"ENTERTAINMENT", nil);
                        break;
                    }
                }
                
                NSDictionary *dataSourceObj = @{SCUDefaultTableViewCellKeyTitle: title,
                                                SCUDefaultTableViewCellKeyDetailTitle: [self cellTextWith:notification],
                                                SCUDefaultTableViewCellKeyModelObject: notification,
                                                SCUNotificationToggleTableViewCellKeyValue: @(notification.enabled),
                                                SCUNotificationsModelObjectKeyCellType: @(SCUNotificationsCellTypeToggle),
                                                SCUNotificationsModelObjectKeyType: @(SCUNotificationModelTypeNotification),
                                                };
                [data addObject:dataSourceObj];
            }
            
            sSelf.dataSource = [data copy];
        }
        else
        {
            //-------------------------------------------------------------------
            // JRL TODO: handle error
            //-------------------------------------------------------------------
        }
        
        [sSelf.delegate endRefresh];
        [sSelf.delegate reloadData];
    }];
}

- (void)deleteAtIndexPath:(NSIndexPath *)indexPath
{
    SAVNotification *notificationToRemove = [self notificationForIndexPath:indexPath];
    NSMutableArray *dataSource = [self.dataSource mutableCopy];
    [dataSource removeObject:[self modelObjectForIndexPath:indexPath]];
    self.dataSource = [dataSource copy];
    [self.delegate reloadData];
    
    SAVWeakSelf;

    [[SavantControl sharedControl].notificationManager unregisterNotification:notificationToRemove completionHandler:^(BOOL success, NSError *error) {
        if (!success)
        {
            SCUAlertView *alert = [[SCUAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription buttonTitles:@[@"Dismiss"]];
            [alert show];
        }
        [wSelf loadData];
    }];
}

- (NSString *)cellTextWith:(SAVNotification *)notification
{
    NSString *text = @"";
    NSString *timeSegment = [self whenStringWith:notification];
    
    switch (notification.serviceType)
    {
        case SAVNotificationServiceTypeTemperature:
        case SAVNotificationServiceTypeHumidity:
        {
            NSString *serviceString = @"";
            NSString *modifier;
            
            if (notification.serviceType == SAVNotificationServiceTypeTemperature)
            {
                serviceString = @"temperature";
                modifier = @"\u00B0";
            }
            else
            {
                serviceString = @"humidity";
                modifier = @"%";
            }
            
            if ([notification.triggerValues count] == 1)
            {
                NSString *comparison = @"";
                
                if ([notification.triggerComparison isEqualToString:@"<"])
                {
                    comparison = @"below";
                }
                else if ([notification.triggerComparison isEqualToString:@">"])
                {
                    comparison = @"above";
                }
                text = [NSString stringWithFormat:@"The %@ is %@ %ld%@%@ in the %@.", serviceString, comparison, (long)[[notification.triggerValues firstObject] integerValue], modifier, timeSegment, [self zonesOrRoomsStringWith:notification.zones]];
            }
            else if ([notification.triggerValues count] > 1)
            {
                text = [NSString stringWithFormat:@"The %@ is below %ld%@ or higher than %ld%@%@ in the %@.", serviceString, (long)[[notification.triggerValues firstObject] integerValue], modifier, (long)[[notification.triggerValues lastObject] integerValue], modifier, timeSegment, [self zonesOrRoomsStringWith:notification.zones]];
            }
            else
            {
                //error, triggerValues count is not one or two
            }
            break;
        }
        case SAVNotificationServiceTypeLighting:
        case SAVNotificationServiceTypeEntertainment:
        {
            NSString *serviceSegment = (notification.serviceType == SAVNotificationServiceTypeEntertainment) ? @"Entertainment is" : @"The lights are";
            
            NSString *onOff = @"";
            if ([[notification.triggerValues firstObject] integerValue] == 0)
            {
                onOff = @"off";
            }
            else
            {
                onOff = @"on";
            }
            
            text = [NSString stringWithFormat:@"%@ %@%@ in the %@.", serviceSegment, onOff, timeSegment, [self zonesOrRoomsStringWith:notification.rooms]];
            break;
        }
    }
    return text;
}

- (NSString *)zonesOrRoomsStringWith:(NSArray *)array
{
    NSString *stringVersion = @"";
    if (!array || ([array count] < 1))
    {
        stringVersion = @"home";
    }
    else if ([array count] == 1)
    {
        stringVersion = [array firstObject];
    }
    else
    {
        for (NSUInteger i = 0; i < [array count]; i++)
        {
            NSString *zone = [array objectAtIndex:i];
            
            if (ULTIMATE_ITEM)
            {
                stringVersion = [stringVersion stringByAppendingString:[NSString stringWithFormat:@"or %@", zone]];
            }
            else if (PENULTIMATE_ITEM)
            {
                stringVersion = [stringVersion stringByAppendingString:[NSString stringWithFormat:@"%@ ", zone]];
            }
            else
            {
                stringVersion = [stringVersion stringByAppendingString:[NSString stringWithFormat:@"%@, ", zone]];
            }
        }
    }
    return stringVersion;
}

- (NSString *)whenStringWith:(SAVNotification *)notification
{
    NSString *whenString = @"";
    NSString *timeSegment = @"";
    NSString *dateSegment = @"";
    NSString *daySegment = @"";

    NSMutableArray *allSegments = [[NSMutableArray alloc] init];
    
    if (!notification.isAllDay && ![notification.timeString isEqualToString:@""])
    {
        timeSegment = [NSString stringWithFormat:@" between %@", notification.timeString];
        [allSegments addObject:timeSegment];
    }
    if (![notification.dateString isEqualToString:@"All Year"] && ![notification.dateString isEqualToString:@""])
    {
        dateSegment = [NSString stringWithFormat:@" from %@", notification.dateString];
        [allSegments addObject:dateSegment];
    }
    if (![notification.dayString isEqualToString:@"Everyday"] && ![notification.dayString isEqualToString:@""])
    {
        daySegment = [NSString stringWithFormat:@" on %@", notification.dayString];
        [allSegments addObject:daySegment];
    }
    
    if ([allSegments count] == 3)
    {
        whenString = [NSString stringWithFormat:@"%@,%@,%@,", allSegments[0], allSegments[1], allSegments[2]];
    }
    else if ([allSegments count] == 2)
    {
        whenString = [NSString stringWithFormat:@"%@,%@,", allSegments[0], allSegments[1]];
    }
    else if ([allSegments count] == 1)
    {
        whenString = [NSString stringWithFormat:@"%@", allSegments[0]];
    }
    
    return whenString;
}

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on) {
        [wSelf switchDidToggleOn:on forIndexPath:indexPath];
    };
}

- (void)switchDidToggleOn:(BOOL)on forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [[SavantControl sharedControl].notificationManager setNotification:[wSelf notificationForIndexPath:indexPath]
                                                               enabled:on
                                                     completionHandler:^(BOOL success, NSError *error) {
                                                         if (success)
                                                         {
                                                             [self loadData];
                                                         }
                                                         else
                                                         {
                                                             SCUAlertView *alert = [[SCUAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription buttonTitles:@[@"Dismiss"]];
                                                             [alert show];
                                                             
                                                             [self.delegate reloadIndexPath:indexPath];
                                                         }
                                                     }];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUNotificationsCellType type = [[self modelObjectForIndexPath:indexPath][SCUNotificationsModelObjectKeyCellType] unsignedIntegerValue];
    return type;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = self.dataSource[indexPath.row];
    
    return modelObject;
}

- (SAVNotification *)notificationForIndexPath:(NSIndexPath *)indexPath
{
    SAVNotification *notification = nil;
    
    if (indexPath)
    {
        notification = [self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];
    }
    
    return notification;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self cellTypeForIndexPath:indexPath] == SCUNotificationsCellTypeToggle)
    {
        [self.delegate presentEditNotification:[self notificationForIndexPath:indexPath]];
    }
}

@end
