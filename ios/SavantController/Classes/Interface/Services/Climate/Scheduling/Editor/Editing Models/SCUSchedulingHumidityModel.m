//
//  SCUSchedulingHumidityModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingHumidityModel.h"
#import "SCUSchedulingPickerCell.h"
#import "SCUInterface.h"
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingHumidityModel ()

@property SCUSchedulingHumidityMode mode;
@property (nonatomic, getter=isHumidityModel) BOOL humidityModel;

@end

@implementation SCUSchedulingHumidityModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super initWithSchedule:schedule];
    
    if (self)
    {
        self.modePresent = NO;
        self.humidityModel = YES;
        
        NSArray *modes = [self getPossibleModes];
        if ([modes count] >= 2)
        {
            self.mode = SCUSchedulingHumidityModeBoth;
        }
        else if ([modes count])
        {
            self.mode = [[modes firstObject] integerValue];
        }
        
        self.possibleModes = modes;
    }
    
    return self;
}

- (NSArray *)getPossibleModes
{
    NSMutableSet *modes = [NSMutableSet set];
    for (NSString *zone in self.schedule.zones)
    {
        NSArray *zoneEntities = [[[SavantControl sharedControl] data] HVACEntities:nil zone:zone service:nil];
        for (SAVHVACEntity *entity in zoneEntities)
        {
            if (entity.humidifySetPoint)
            {
                [modes addObject:@(SCUSchedulingHumidityModeHumidify)];
            }
            if (entity.dehumidifySetPoint)
            {
                [modes addObject:@(SCUSchedulingHumidityModeDehumidify)];
            }
            if (!entity.dehumidifySetPoint && !entity.humidifySetPoint && entity.humiditySPCount > 0)
            {
                [modes addObject:@(SCUSchedulingHumidityModeHumidity)];
            }
        }
    }
    return modes.count ? [modes allObjects] : nil;
}

- (NSArray *)setPoints
{
    return self.schedule.humiditySetPoints;
}

- (void)setSetPoints:(NSArray *)setPoints
{
    self.schedule.humiditySetPoints = setPoints;
}

- (CGFloat)range
{
    return self.schedule.humidityRange;
}

- (CGFloat)maxPoint
{
    return self.schedule.humidityMaxPoint;
}

- (CGFloat)minPoint
{
    return self.schedule.humidityMinPoint;
}

- (CGFloat)buffer
{
    return self.schedule.humidityPointBuffer;
}

- (SAVClimateSetPoint *)buildSetpoint
{
    SAVClimateSetPointType type = (self.mode == SCUSchedulingHumidityModeHumidity) ? SAVClimateSetPointType_Humidity : SAVClimateSetPointType_HumidifyDehumidify;
    return [[SAVClimateSetPoint alloc] initWithRange:self.range
                                            minPoint:self.minPoint
                                              buffer:self.buffer
                                              point1:self.maxPoint
                                              point2:self.minPoint
                                                time:nil
                                             andType:type];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = nil;

    if (indexPath.row == 0 && self.modePresent)
    {
        modelObject = @{SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeMode),
                        SCUSchedulingPickerCellKeyCellModeTitle: @"Auto"};
    }
    else if ((long)indexPath.row == (long)self.setPoints.count + 1 && self.modePresent)
    {
        modelObject = @{SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeAdd)};
    }
    else if ([self.setPoints count] > (NSUInteger)indexPath.row)
    {
        SAVClimateSetPoint *setPoint = [self setPointForRow:indexPath.row];
  
        modelObject = @{SCUSchedulingPickerCellKeyTime: setPoint.time,
                        SCUSchedulingPickerCellKeySetPoint1: @(setPoint.rawPoint1),
                        SCUSchedulingPickerCellKeySetPoint2: @(setPoint.rawPoint2),
                        SCUSchedulingPickerCellKeyMode: @(self.mode),
                        SCUSchedulingPickerCellKeyUnitsString: @"%",
                        SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeHumidity),
                        SCUSchedulingPickerCellKeyMaxColor: [UIColor sav_colorWithRGBValue:0xebe182],
                        SCUSchedulingPickerCellKeyMinColor: [UIColor sav_colorWithRGBValue:0x3fb246],
                        };

        // Change title based on mode -- mainly for Humidity mode
        switch (self.mode)
        {
            case SCUSchedulingHumidityModeHumidify:
            case SCUSchedulingHumidityModeDehumidify:
            case SCUSchedulingHumidityModeBoth:
                modelObject = [modelObject dictionaryByAddingObject:NSLocalizedString(@"Dehumidify", nil) forKey:SCUSchedulingPickerCellKeyMaxTitle];
                modelObject = [modelObject dictionaryByAddingObject:NSLocalizedString(@"Humidify", nil) forKey:SCUSchedulingPickerCellKeyMinTitle];
                break;
            case SCUSchedulingHumidityModeHumidity:
                modelObject = [modelObject dictionaryByAddingObject:NSLocalizedString(@"Humidity", nil) forKey:SCUSchedulingPickerCellKeyMinTitle];
                break;
        }
        
    }

    return modelObject;
}

@end
