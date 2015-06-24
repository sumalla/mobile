//
//  SCUSchedulingTempModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingTempModel.h"
#import "SCUSchedulingPickerCell.h"
#import "SCUButton.h"
#import "SCUPopoverMenu.h"
#import "SCUPickerView.h"
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingTempModel ()

@property NSDateFormatter *dateFormatter;
@property (nonatomic, getter=isHumidityModel) BOOL humidityModel;

@end

@implementation SCUSchedulingTempModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super initWithSchedule:schedule];
    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateFormat = @"HH:mm:ss";
        self.possibleModes = [self getPossibleModes];
        self.modePresent = YES;
    }
    return self;
}

- (NSString *)nameForScheduleMode:(SAVClimateScheduleMode)mode
{
    switch (mode)
    {
        case SAVClimateScheduleMode_Auto:
            return NSLocalizedString(@"Auto", nil);
        case SAVClimateScheduleMode_Cool:
            return NSLocalizedString(@"Cool", nil);
        case SAVClimateScheduleMode_Heat:
            return NSLocalizedString(@"Heat", nil);
        default:
            return nil;
    }
}

- (BOOL)hvacEntity:(SAVHVACEntity *)entity containsCommand:(NSString *)command
{
    return [entity.service.commands containsObject:command];
}

- (NSArray *)getPossibleModes
{
    NSCountedSet *modes = [[NSCountedSet alloc] init];
    NSUInteger totalCount = 0;
    for (NSString *zone in self.schedule.zones)
    {
        NSArray *zoneEntities = [[[SavantControl sharedControl] data] HVACEntities:nil zone:zone service:nil];
        for (SAVHVACEntity *entity in zoneEntities)
        {
            if (entity.heatSetPoint && [self hvacEntity:entity containsCommand:@"SetHVACModeHeat"])
            {
                [modes addObject:@(SAVClimateScheduleMode_Heat)];
            }
            if (entity.coolSetPoint && [self hvacEntity:entity containsCommand:@"SetHVACModeCool"])
            {
                [modes addObject:@(SAVClimateScheduleMode_Cool)];
            }
            if ([self hvacEntity:entity containsCommand:@"SetHVACModeAuto"]  && entity.autoMode)
            {
                [modes addObject:@(SAVClimateScheduleMode_Auto)];
            }
            
            totalCount++;
        }
    }
    
    NSMutableArray *modesArray = [NSMutableArray array];
    
    if ([modes countForObject:@(SAVClimateScheduleMode_Auto)] == totalCount)
    {
        [modesArray addObject:@(SAVClimateScheduleMode_Auto)];
    }
    if ([modes countForObject:@(SAVClimateScheduleMode_Heat)] == totalCount)
    {
        [modesArray addObject:@(SAVClimateScheduleMode_Heat)];
    }
    if ([modes countForObject:@(SAVClimateScheduleMode_Cool)] == totalCount)
    {
        [modesArray addObject:@(SAVClimateScheduleMode_Cool)];
    }
    
    return modesArray.count ? [modesArray copy] : nil;
}

- (void)setModeAtIndex:(NSInteger)index
{
    if (self.possibleModes)
    {
        if (self.possibleModes.count > (NSUInteger)index)
        {
            SAVClimateScheduleMode mode = [self.possibleModes[index] integerValue];
            self.schedule.hvacMode = mode;
        }
    }
}

- (NSUInteger)setTime:(NSDate *)time forRow:(NSUInteger)row
{
    SAVClimateSetPoint *setPoint = [self setPointForRow:row];
    setPoint.time = [self.dateFormatter stringFromDate:time];

    [self sortSetPoints];

    return [self.setPoints indexOfObject:setPoint];
}

- (NSDate *)timeForRow:(NSUInteger)row
{
    SAVClimateSetPoint *setPoint = [self setPointForRow:row];

    return [self.dateFormatter dateFromString:setPoint.time];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    if (self.modePresent)
    {
        return [self.setPoints count] ? [self.setPoints count] + 1 : 2;
    }
    else
    {
        return [self.setPoints count] ? [self.setPoints count] : 1;
    }
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = nil;
    
    if (indexPath.row == 0 && self.modePresent)
    {
        self.possibleModes = [self getPossibleModes];
        SAVClimateScheduleMode modeType = [[self.possibleModes firstObject] integerValue];
        
        if ([self.possibleModes containsObject:@(self.schedule.hvacMode)])
        {
            modeType = self.schedule.hvacMode;
        }
        NSString *mode = [self nameForScheduleMode:modeType];

        modelObject = @{SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeMode),
                        SCUSchedulingPickerCellKeyModeEnabled: @(YES),
                        SCUSchedulingPickerCellKeyCellModeTitle: mode,
                        };
    }
    else if ((long)indexPath.row == (long)self.setPoints.count + 1 && self.modePresent)
    {
        modelObject = @{SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeAdd)};
    }
    else if ([self.setPoints count] > 0)
    {
        SAVClimateSetPoint *setPoint = [self setPointForRow:indexPath.row];

        self.possibleModes = [self getPossibleModes];
        SAVClimateScheduleMode modeType = [[self.possibleModes firstObject] integerValue];
        
        if ([self.possibleModes containsObject:@(self.schedule.hvacMode)])
        {
            modeType = self.schedule.hvacMode;
        }

        if (setPoint.time)
        {
            modelObject = @{SCUSchedulingPickerCellKeyTime: setPoint.time,
                            SCUSchedulingPickerCellKeySetPoint1: @(setPoint.rawPoint1),
                            SCUSchedulingPickerCellKeySetPoint2: @(setPoint.rawPoint2),
                            SCUSchedulingPickerCellKeyMode: @(modeType),
                            SCUSchedulingPickerCellKeyUnitsString: @"\u00B0",
                            SCUSchedulingPickerCellKeyCellType: @(SCUSchedulingPickerCellTypeTemp),
                            SCUSchedulingPickerCellKeyMaxColor: [UIColor sav_colorWithRGBValue:0xb3e6f9],
                            SCUSchedulingPickerCellKeyMinColor: [UIColor sav_colorWithRGBValue:0xfc8423],
                            SCUSchedulingPickerCellKeyMaxTitle: NSLocalizedString(@"Max at", nil),
                            SCUSchedulingPickerCellKeyMinTitle: NSLocalizedString(@"Min at", nil)
                            };
        }
    }
    
    return modelObject;
}

- (void)sortSetPoints
{
    NSMutableArray *setPoints = [NSMutableArray arrayWithArray:self.setPoints];

    [setPoints sortUsingComparator:^NSComparisonResult(SAVClimateSetPoint *obj1, SAVClimateSetPoint *obj2) {
        return [[self.dateFormatter dateFromString:obj1.time] timeIntervalSince1970] > [[self.dateFormatter dateFromString:obj2.time] timeIntervalSince1970];
    }];
    
    [self.delegate reorderIndexPathsWithData:setPoints];
    self.setPoints = setPoints;
}

- (NSArray *)setPoints
{
    return self.schedule.temperatureSetPoints;
}

- (CGFloat)range
{
    return self.schedule.temperatureRange;
}

- (CGFloat)maxPoint
{
    return self.schedule.temperatureMaxPoint;
}

- (CGFloat)minPoint
{
    return self.schedule.temperatureMinPoint;
}

- (CGFloat)buffer
{
    return self.schedule.temperaturePointBuffer;
}

- (void)setSetPoints:(NSArray *)setPoints
{
    self.schedule.temperatureSetPoints = setPoints;
}

- (SAVClimateSetPoint *)setPointForRow:(NSUInteger)row
{
    SAVClimateSetPoint *setPoint = nil;
    
    if (self.modePresent)
    {
        if (row != 0 && row != [self.setPoints count] + 1 && [self.setPoints count])
        {
            setPoint = self.setPoints[row - 1];
        }
    }
    else
    {
        if ([self.setPoints count] > row)
        {
            setPoint = self.setPoints[row];
        }
    }

    return setPoint;
}

- (SAVClimateSetPoint *)setPointAfterRow:(NSUInteger)row
{
    return [self setPointForRow:row + 1];
}

- (SAVClimateSetPoint *)buildSetpoint
{
    return [[SAVClimateSetPoint alloc] initWithRange:self.range
                                            minPoint:self.minPoint
                                              buffer:self.buffer
                                              point1:self.maxPoint
                                              point2:self.minPoint
                                                time:nil
                                             andType:SAVClimateSetPointType_Temperature];
}

- (void)configureCell:(id)c withType:(NSUInteger)type indexPath:(NSIndexPath *)updatedIndexPath
{
    SCUSchedulingPickerCell *cell = (SCUSchedulingPickerCell *)c;

    SAVWeakSelf;
    [cell.addButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        NSIndexPath *updatedIndexPath = [self.delegate indexPathForCell:cell];
        SAVClimateSetPoint *setPoint = [wSelf setPointForRow:updatedIndexPath.row];
        SAVClimateSetPoint *nextPoint = [wSelf setPointAfterRow:updatedIndexPath.row];

        [self.dateFormatter setDateFormat:@"HH:mm:ss"];
        SAVClimateSetPoint *newSetPoint = nil;

        if (setPoint)
        {
            newSetPoint = [setPoint copy];
        }
        else
        {
            newSetPoint = [self buildSetpoint];
        }

        NSTimeInterval time = 0;

        if (setPoint)
        {
            NSTimeInterval nextTime = 0;
            NSTimeInterval previousTime = [[self.dateFormatter dateFromString:setPoint.time] timeIntervalSince1970];

            if (nextPoint)
            {
                nextTime = [[self.dateFormatter dateFromString:nextPoint.time] timeIntervalSince1970];
            }
            else
            {
                nextTime = [[self.dateFormatter dateFromString:@"23:59:59"] timeIntervalSince1970] + 60;
            }

            time = previousTime + (nextTime - previousTime) / 2;
        }
        else
        {
            time = [[self.dateFormatter dateFromString:@"00:00:00"] timeIntervalSince1970];
        }

        newSetPoint.time = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];

        NSMutableArray *mutableSetPoints = [NSMutableArray arrayWithArray:self.setPoints];

        if (!setPoint)
        {
            if (self.modePresent)
            {
                [mutableSetPoints insertObject:newSetPoint atIndex:updatedIndexPath.row - 1];
            }
            else
            {
                [mutableSetPoints insertObject:newSetPoint atIndex:updatedIndexPath.row];
            }
            wSelf.setPoints = mutableSetPoints;

            [wSelf.delegate reloadRowAtIndexPath:updatedIndexPath];
        }
        else
        {
            
            if (self.modePresent)
            {
                [mutableSetPoints insertObject:newSetPoint atIndex:updatedIndexPath.row];
            }
            else
            {
                [mutableSetPoints insertObject:newSetPoint atIndex:updatedIndexPath.row + 1];
            }
            
            wSelf.setPoints = mutableSetPoints;

            [wSelf.delegate insertRowAtIndexPath:[NSIndexPath indexPathForRow:updatedIndexPath.row + 1 inSection:updatedIndexPath.section]];
        }
    }];

    [cell.deleteButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        NSIndexPath *updatedIndexPath = [self.delegate indexPathForCell:cell];
        NSMutableArray *mutableSetPoints = [NSMutableArray arrayWithArray:wSelf.setPoints];
        if (wSelf.modePresent)
        {
            [mutableSetPoints removeObjectAtIndex:updatedIndexPath.row - 1];
        }
        else
        {
            [mutableSetPoints removeObjectAtIndex:updatedIndexPath.row];
        }
        wSelf.setPoints = mutableSetPoints;

        if ([wSelf.setPoints count])
        {
            [wSelf.delegate deleteRowAtIndexPath:updatedIndexPath];
        }
        else
        {
            [wSelf.delegate reloadRowAtIndexPath:updatedIndexPath];
        }
    }];



    cell.maxPickerView.handler = ^(SCUPickerViewDirection direction){
        SAVClimateSetPoint *setPoint = [wSelf setPointForRow:updatedIndexPath.row];

        switch (direction)
        {
            case SCUPickerViewDirectionUp:
                setPoint.rawPoint1++;
                break;
            case SCUPickerViewDirectionDown:
                if ((setPoint.rawPoint2 >= setPoint.minPoint) && (setPoint.rawPoint1 - setPoint.rawPoint2) <= setPoint.buffer)
                {
                    setPoint.rawPoint2 = floorf(setPoint.rawPoint2) - 1.0;
                }
                setPoint.rawPoint1 = floorf(setPoint.rawPoint1) - 1.0;
                break;
            case SCUPickerViewDirectionLeft:
            case SCUPickerViewDirectionRight:
                break;
        }
        [cell setMaxSetPoint:setPoint.rawPoint1];
        [cell setMinSetPoint:setPoint.rawPoint2];
    };

    cell.minPickerView.handler = ^(SCUPickerViewDirection direction){
        SAVClimateSetPoint *setPoint = [wSelf setPointForRow:updatedIndexPath.row];

        switch (direction)
        {
            case SCUPickerViewDirectionUp:
                if (setPoint.rawPoint1 <= (setPoint.minPoint + setPoint.range) && (setPoint.rawPoint1 - setPoint.rawPoint2) <= setPoint.buffer)
                {
                    setPoint.rawPoint1 = floorf(setPoint.rawPoint1) + 1.0;
                }
                setPoint.rawPoint2 = floorf(setPoint.rawPoint2) + 1.0;
                break;
            case SCUPickerViewDirectionDown:
                setPoint.rawPoint2 = floorf(setPoint.rawPoint2) - 1.0;
                break;
            case SCUPickerViewDirectionLeft:
            case SCUPickerViewDirectionRight:
                break;
        }
        [cell setMinSetPoint:setPoint.rawPoint2];
        [cell setMaxSetPoint:setPoint.rawPoint1];
    };
}

@end
