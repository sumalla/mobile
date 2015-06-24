//
//  SCUNotificationAddServiceViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 1/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUNotificationCreationTableViewController.h"
#import "SCUNotificationAddServiceViewModel.h"
#import "SCUNotificationAddServiceTableViewController.h"

#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSInteger, SCUNotificationHVACCapabilities)
{
    SCUNotificationCreationSupportsNothing,
    SCUNotificationCreationSupportsTemperature,
    SCUNotificationCreationSupportsHumidity,
    SCUNotificationCreationSupportsTemperatureAndHumidity,
};

@interface SCUNotificationAddServiceViewModel ()

@property (nonatomic) NSArray *dataSource;

@end

static NSString *SCUNotificationAddServiceViewModelKeySectionArray  = @"SCUNotificationAddServiceViewModelKeySectionArray";
static NSString *SCUNotificationAddServiceViewModelKeySectionTitle  = @"SCUNotificationAddServiceViewModelKeySectionTitle";
static NSString *SCUNotificationAddServiceViewModelKeyServiceToggle = @"SCUNotificationAddServiceViewModelKeyServiceToggle";

@implementation SCUNotificationAddServiceViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    NSString *leftmostService = [[self availableServices] firstObject];
    
    if ([leftmostService isEqualToString:SCUNotificationIconClimate])
    {
        notification.serviceType = SAVNotificationServiceTypeTemperature;
    }
    else if ([leftmostService isEqualToString:SCUNotificationIconEntertainment])
    {
        notification.serviceType = SAVNotificationServiceTypeEntertainment;
    }
    else if ([leftmostService isEqualToString:SCUNotificationIconLighting])
    {
        notification.serviceType = SAVNotificationServiceTypeLighting;
    }
    
    self = [super initWithNotification:notification];
    
    if (self)
    {
        [self prepareData];
    }
    
    return self;
}

- (void)prepareData
{
    NSArray *dataSource = nil;
    
    switch (self.notification.serviceType)
    {
        case SAVNotificationServiceTypeLighting:
            dataSource = @[@{SCUNotificationAddServiceViewModelKeySectionTitle: NSLocalizedString(@"Lighting", nil),
                           SCUNotificationAddServiceViewModelKeySectionArray:
                               @[@{SCUDefaultTableViewCellKeyTitle: @"Lights are on",
                                 SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                 SCUNotificationAddServiceViewModelKeyServiceToggle: @1},
                               @{SCUDefaultTableViewCellKeyTitle: @"Lights are off",
                                 SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                 SCUNotificationAddServiceViewModelKeyServiceToggle: @0}]}];
            break;
        case SAVNotificationServiceTypeHumidity:
        case SAVNotificationServiceTypeTemperature:
        {
            NSArray *capabilitiesArr = @[];
            
            switch ([self HVACCapabilities])
            {
                case SCUNotificationCreationSupportsTemperatureAndHumidity:
                    capabilitiesArr = @[@{SCUDefaultTableViewCellKeyTitle: @"Temperature range",
                                             SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)},
                                           @{SCUDefaultTableViewCellKeyTitle: @"Humidity range",
                                             SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)}];
                    break;
                case SCUNotificationCreationSupportsHumidity:
                    capabilitiesArr = @[@{SCUDefaultTableViewCellKeyTitle: @"Humidity range",
                                          SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)}];
                    break;
                case SCUNotificationCreationSupportsTemperature:
                    capabilitiesArr = @[@{SCUDefaultTableViewCellKeyTitle: @"Temperature range",
                                          SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)}];
                    break;
            }
            
            dataSource = @[@{SCUNotificationAddServiceViewModelKeySectionTitle: NSLocalizedString(@"Climate", nil),
                             SCUNotificationAddServiceViewModelKeySectionArray:capabilitiesArr}];
        }
            break;
        case SAVNotificationServiceTypeEntertainment:
            dataSource = @[@{SCUNotificationAddServiceViewModelKeySectionTitle: NSLocalizedString(@"Entertainment", nil),
                             SCUNotificationAddServiceViewModelKeySectionArray:
                             @[@{SCUDefaultTableViewCellKeyTitle: @"A/V services are on",
                                 SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                 SCUNotificationAddServiceViewModelKeyServiceToggle: @1},
                               @{SCUDefaultTableViewCellKeyTitle: @"A/V services are off",
                                 SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                 SCUNotificationAddServiceViewModelKeyServiceToggle: @0}]}];
            break;
    }

    if (!dataSource)
    {
        dataSource = @[];
    }
    
    self.dataSource = [dataSource copy];
}

- (SCUNotificationHVACCapabilities)HVACCapabilities
{
    SAVData *data = [SavantControl sharedControl].data;
    
    BOOL hasTemperature = NO;
    BOOL hasHumidity = NO;
    
    if (data)
    {
        NSArray *HVACEntites = [data HVACEntities:nil zone:nil service:[[SAVService alloc] initWithString:@"SVC_ENV_HVAC" queryService:NO]];
        
        for (SAVHVACEntity *entity in HVACEntites)
        {
            if (!hasTemperature && entity.tempSPCount > 0)
            {
                hasTemperature = YES;
            }
            if (!hasHumidity && entity.humiditySPCount > 0)
            {
                hasHumidity = YES;
            }
        }
    }
    
    if (hasTemperature && hasHumidity)
    {
        return SCUNotificationCreationSupportsTemperatureAndHumidity;
    }
    else if (hasHumidity)
    {
        return SCUNotificationCreationSupportsHumidity;
    }
    else if (hasTemperature)
    {
        return SCUNotificationCreationSupportsTemperature;
    }
    else
    {
        return SCUNotificationCreationSupportsNothing;
    }
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUNotificationAddServiceViewModelKeySectionArray];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return self.dataSource[section][SCUNotificationAddServiceViewModelKeySectionTitle];
}

- (void)selectedIndex:(NSInteger)index forImage:(NSString *)imageName
{
    NSString *selectedServiceForIcon = [self.availableServices objectAtIndex:index];
    
    if ([selectedServiceForIcon isEqualToString:SCUNotificationIconEntertainment])
    {
        self.notification.serviceType = SAVNotificationServiceTypeEntertainment;
    }
    else if ([selectedServiceForIcon isEqualToString:SCUNotificationIconClimate])
    {
        self.notification.serviceType = SAVNotificationServiceTypeTemperature;
    }
    else
    {
        self.notification.serviceType = SAVNotificationServiceTypeLighting;
    }
    
    [self prepareData];
    
    [self.delegate reloadData];
}

- (NSInteger)indexForServiceType:(SAVNotificationServiceType)type
{
    switch (type)
    {
        case SAVNotificationServiceTypeLighting:
            return 0;
        case SAVNotificationServiceTypeTemperature:
        case SAVNotificationServiceTypeHumidity:
            return 1;
        case SAVNotificationServiceTypeEntertainment:
            return 2;
    }
}

- (NSArray *)availableServices
{
    NSMutableSet *services = [NSMutableSet set];

    NSArray *rooms = [[SavantControl sharedControl].data allRooms];
    for (SAVRoom *room in rooms)
    {
        if ([room hasAV])
        {
            [services addObject:SCUNotificationIconEntertainment];
        }
        
        if ([room hasHVAC])
        {
            [services addObject:SCUNotificationIconClimate];
        }
        
        if ([room hasLighting])
        {
            [services addObject:SCUNotificationIconLighting];
        }
    }
    
    NSMutableArray *allObjects = [[services allObjects] mutableCopy];
    NSMutableArray *sorted = [[NSMutableArray alloc] init];
    
    if ([allObjects containsObject:SCUNotificationIconLighting])
    {
        [sorted addObject:SCUNotificationIconLighting];
    }
    if ([allObjects containsObject:SCUNotificationIconClimate])
    {
        [sorted addObject:SCUNotificationIconClimate];
    }
    if ([allObjects containsObject:SCUNotificationIconEntertainment])
    {
        [sorted addObject:SCUNotificationIconEntertainment];
    }
    
    return sorted;
}

- (NSInteger)toggleStatusForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger toggleValue = [self.dataSource[indexPath.section][SCUNotificationAddServiceViewModelKeySectionArray][indexPath.row][SCUNotificationAddServiceViewModelKeyServiceToggle] integerValue];
    
    return toggleValue;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    self.notification.triggerValues = [NSMutableArray arrayWithObjects:@([self toggleStatusForIndexPath:indexPath]), nil];
    
    if (self.notification.serviceType == SAVNotificationServiceTypeTemperature)
    {
        self.notification.rooms = [NSMutableArray array];
        self.notification.serviceType = [self HVACServiceTypeForIndexPath:indexPath];
    }
    else if (self.notification.serviceType == SAVNotificationServiceTypeHumidity)
    {
        self.notification.rooms = [NSMutableArray array];
        self.notification.serviceType = [self HVACServiceTypeForIndexPath:indexPath];
    }
    else
    {
        self.notification.zones = [NSMutableArray array];
    }
    
    [self.delegate moveToRuleScreen];
}

- (SAVNotificationServiceType)HVACServiceTypeForIndexPath:(NSIndexPath *)indexPath
{
    switch ([self HVACCapabilities])
    {
        case SCUNotificationCreationSupportsHumidity:
            return SAVNotificationServiceTypeHumidity;
        case SCUNotificationCreationSupportsTemperatureAndHumidity:
            if (indexPath.row == 0)
            {
                return SAVNotificationServiceTypeTemperature;
            }
            else
            {
                return SAVNotificationServiceTypeHumidity;
            }
    }
    return SAVNotificationServiceTypeTemperature;
}

- (BOOL)isFlat
{
    return NO;
}

@end
