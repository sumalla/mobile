//
//  SCUSchedulingEditorModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditorModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUDefaultCollectionViewCell.h"
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingEditorModel ()

@property SAVClimateSchedule *schedule;
@property NSArray *dataSource;

@end

@implementation SCUSchedulingEditorModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.schedule = schedule;
        [self prepareData];
    }
    return self;
}

- (SCUSchedulingEditorType)typeForIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row;
}

- (void)prepareData
{
    NSMutableArray *data = [NSMutableArray array];
    
    if ([UIDevice isPad])
    {
        [data addObject:@{SCUDefaultCollectionViewCellKeyTitle: [NSLocalizedString(@"On These Days", nil) uppercaseString],
                          SCUDefaultCollectionViewCellKeyModelObject: self.schedule,
                          @"type": @(SCUSchedulingEditorType_Days)}];
        [data addObject:@{SCUDefaultCollectionViewCellKeyTitle: [NSLocalizedString(@"In These Rooms", nil) uppercaseString],
                          SCUDefaultCollectionViewCellKeyModelObject: self.schedule,
                          @"type": @(SCUSchedulingEditorType_Rooms)}];
        if ([self isTemperaturePresent])
        {
            [data addObject:@{SCUDefaultCollectionViewCellKeyTitle: [NSLocalizedString(@"Set Temp Points", nil) uppercaseString],
                              SCUDefaultCollectionViewCellKeyModelObject: self.schedule,
                              @"type": @(SCUSchedulingEditorType_Temp)}];
        }
        if ([self isHumidityPresent])
        {
            [data addObject:@{SCUDefaultCollectionViewCellKeyTitle: [NSLocalizedString(@"Set Humidity Points", nil) uppercaseString],
                              SCUDefaultCollectionViewCellKeyModelObject: self.schedule,
                              @"type": @(SCUSchedulingEditorType_Humidity)}];
        }
    }
    else
    {
        [data addObject:@{SCUDefaultTableViewCellKeyTitle: [NSLocalizedString(@"On These Days", nil) uppercaseString]}];
        [data addObject:@{SCUDefaultTableViewCellKeyTitle: [NSLocalizedString(@"In These Rooms", nil) uppercaseString]}];
        if ([self isTemperaturePresent])
        {
            [data addObject:@{SCUDefaultTableViewCellKeyTitle: [NSLocalizedString(@"Set Temp Points", nil) uppercaseString]}];
        }
        if ([self isHumidityPresent])
        {
            [data addObject:@{SCUDefaultTableViewCellKeyTitle: [NSLocalizedString(@"Set Humidity Points", nil) uppercaseString]}];
        }
        
        for (NSIndexPath *path in self.selectedIndexPaths)
        {
            NSUInteger idx = path.row;
            
            if ([data count] >= idx)
            {
                NSMutableDictionary *dict = [data[idx] mutableCopy];
                dict[SCUDefaultTableViewCellKeyModelObject] = self.schedule;
                dict[@"type"] = @(idx);
                
                data[idx] = dict;
            }
        }
    }
    
    self.dataSource = data;
}

- (BOOL)isTemperaturePresent
{
    NSDictionary *HVACs = [[[SavantControl sharedControl] data] HVACRoomsInZones];
    for (NSString *zone in [HVACs allKeys])
    {
        NSArray *zoneEntities = [[[SavantControl sharedControl] data] HVACEntities:nil zone:zone service:nil];
        for (SAVHVACEntity *entity in zoneEntities)
        {
            if (entity.tempSPCount > 0 || entity.heatSetPoint || entity.coolSetPoint)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isHumidityPresent
{
    NSDictionary *HVACs = [[[SavantControl sharedControl] data] HVACRoomsInZones];
    for (NSString *zone in [HVACs allKeys])
    {
        NSArray *zoneEntities = [[[SavantControl sharedControl] data] HVACEntities:nil zone:zone service:nil];
        for (SAVHVACEntity *entity in zoneEntities)
        {
            if (entity.humiditySPCount > 0 || entity.humidifySetPoint || entity.dehumidifySetPoint)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)setSelectedIndexPaths:(NSArray *)selectedIndexPaths
{
    _selectedIndexPaths = selectedIndexPaths;

    [self prepareData];
}

@end
