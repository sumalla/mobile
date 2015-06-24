//
//  SCUClimateHistoryModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryModel.h"
#import "SCUInterface.h"
#import "SCUClimateHistoryWeekCell.h"
#import "SCUClimateHistoryDayViewController.h"

#import <SavantControl/SavantControl.h>

#define kNumberOfDays 7

static NSString *const SAVClimateHistory_Heat_Stage_1    = @"heatStage1";
static NSString *const SAVClimateHistory_Heat_Stage_2    = @"heatStage2";
static NSString *const SAVClimateHistory_Heat_Stage_3    = @"heatStage3";
static NSString *const SAVClimateHistory_Cool_Stage_1    = @"coolStage1";
static NSString *const SAVClimateHistory_Cool_Stage_2    = @"coolStage2";
static NSString *const SAVClimateHistory_Cool_Point      = @"coolPoint";
static NSString *const SAVClimateHistory_Heat_Point      = @"heatPoint";
static NSString *const SAVClimateHistory_Humidity_Indoor = @"indoorHumidity";
static NSString *const SAVClimateHistory_Fan_Relay       = @"fanRelay";
static NSString *const SAVClimateHistory_Temp_Indoor     = @"indoorTemp";
static NSString *const SAVClimateHistory_Temp_Outdoor    = @"outdoorTemp";
static NSString *const SAVClimateHistory_Date_Range      = @"dateRange";
static NSString *const SAVClimateHistory_Start_Date      = @"start";
static NSString *const SAVClimateHistory_End_Date        = @"end";

@interface SCUClimateHistoryModel () <DISResultDelegate>

@property SAVDISRequestGenerator *disRequestGenerator;
@property NSArray *dataSource;
@property NSDictionary *plotDataSource;
@property NSTimeInterval fetchingEndDate;

@end

@implementation SCUClimateHistoryModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.disRequestGenerator = [[SAVDISRequestGenerator alloc] initWithApp:@"hvacMonitor"];
        [[SavantControl sharedControl] addDISResultObserver:self forApp:@"hvacMonitor"];
        self.service = service;

        self.serviceGroup = [[SAVServiceGroup alloc] init];
        [self.serviceGroup addService:service];

        //-------------------------------------------------------------------
        // TODO: Handle multiple HVAC zones in a room
        //-------------------------------------------------------------------
        NSArray *zones = nil;
        
        if ([SCUInterface sharedInstance].currentRoom)
        {
            SAVMutableService *dummyService = [[SAVMutableService alloc] init]; // redmine Bug #7984 Lighting controller used as HVAC controller showing up twice
            dummyService.serviceId = @"SVC_ENV_HVAC";
            zones = [[[SavantControl sharedControl].data zonesForRoom:[SCUInterface sharedInstance].currentRoom filteredByService:dummyService] arrayByMappingBlock:^id(SAVService *object) {
                return object.zoneName;
            }];
        }
        else if (service.zoneName)
        {
            zones = @[service.zoneName];
        }

        self.hvacPickerModel = [[SCUHVACPickerModel alloc] initWithHVACArray:zones serviceType:SCUClimateServiceTypeHistory];
        self.hvacPickerModel.delegate = self;

        self.zoneName = [self.hvacPickerModel currentHVACZone];
    }
    return self;
}

- (void)internalSetNewCurrentEntity:(NSObject *)hvacEntity
{
    NSString *oldZoneName = [self.zoneName copy];
    self.zoneName = [(SAVEntity *)hvacEntity zoneName];

    if (![oldZoneName isEqualToString:self.zoneName])
    {
        [self.delegate fetchCurrentData];
    }
}

- (void)fetchStageDataFromStartTime:(NSTimeInterval)startTime toEndTime:(NSTimeInterval)endTime
{
    self.fetchingEndDate = endTime + 86400;
    if (self.zoneName)
    {
        SAVDISRequest *request = [self.disRequestGenerator request:@"fetchStageHistory"
                                                     withArguments:@{@"zone": self.zoneName ? self.zoneName : @"",
                                                                     @"startDate": @(startTime),
                                                                     @"endDate": @(endTime+86400),
                                                                     @"SampleCount": @1008}];
        [[SavantControl sharedControl] sendMessage:request];
    }
}

- (void)fetchAllDataForTime:(NSTimeInterval)time
{
    self.fetchingEndDate = time;
    if (self.zoneName)
    {
        SAVDISRequest *request = [self.disRequestGenerator request:@"fetchHvacHistory"
                                                     withArguments:@{@"zone": self.zoneName,
                                                                     @"startDate": @(time),
                                                                     @"endDate": @(time+86400),
                                                                     @"SampleCount": @144}];
        [[SavantControl sharedControl] sendMessage:request];
    }
}

- (BOOL)isCelsius
{
    SAVService *service = [[self.hvacPickerModel currentHVACEntity] service];
    NSString *celsiusKey = [NSString stringWithFormat:@"%@.%@.isCelsius", service.component, service.logicalComponent];

    return [[[SAVSettings globalSettings] objectForKey:celsiusKey] boolValue];
}

#pragma mark - Week View Collection View Data

- (void)receivedStageDataUpdate:(NSDictionary *)stageData
{
    NSDictionary *dateRange = stageData[SAVClimateHistory_Date_Range];

    if (dateRange && [dateRange[SAVClimateHistory_End_Date] integerValue] == self.fetchingEndDate)
    {
        NSMutableArray *dataSource = [NSMutableArray array];

        NSArray *coolTotals = [self stageTotalsFromData:stageData[@"coolStage1"] forDays:kNumberOfDays];
        NSArray *heatTotals = [self stageTotalsFromData:stageData[@"heatStage1"] forDays:kNumberOfDays];

        NSTimeInterval startDate = [stageData[@"dateRange"][@"start"] integerValue];

        if ([coolTotals count] == kNumberOfDays && [heatTotals count] == kNumberOfDays)
        {
            for (NSUInteger i = 0; i < kNumberOfDays; i++)
            {
                NSInteger secondsInDay = 86400;
                NSInteger dayOffset = i * secondsInDay;

                [dataSource addObject:@{SCUClimateHistoryWeekCellKeyCoolHours: coolTotals[i],
                                        SCUClimateHistoryWeekCellKeyHeatHours: heatTotals[i],
                                        SCUClimateHistoryWeekCellKeyDate: [NSDate dateWithTimeIntervalSince1970:startDate + dayOffset],
                                        SCUClimateHistoryWeekCellKeyServicesFirst: @(self.delegate.isServicesFirst)}];
            }
        }
        
        self.dataSource = dataSource;
        
        [self.delegate reloadData];
    }
}

- (void)receivedAllHistoryUpdate:(NSDictionary *)allHistory
{
    NSDictionary *dateRange = allHistory[SAVClimateHistory_Date_Range];

    if (dateRange && [dateRange[SAVClimateHistory_Start_Date] integerValue] == self.fetchingEndDate)
    {
        self.plotDataSource = allHistory;
        [self.delegate reloadData];
    }
}

- (NSArray *)stageTotalsFromData:(NSArray *)data forDays:(NSInteger)days
{
    NSMutableArray *totals = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Calculate each partition size depending on the data length and
    // requested number of days.
    //-------------------------------------------------------------------
    NSUInteger partitionSize = floor([data count] / (CGFloat)days);

    //-------------------------------------------------------------------
    // Split the original list into the number of partions requested
    //-------------------------------------------------------------------
    NSMutableArray *partitionList = [NSMutableArray array];

    for (NSUInteger n = 0; n < [data count]; n += partitionSize)
    {
        NSUInteger remainingSize = [data count] - n;
        if (remainingSize >= (partitionSize * 2))
        {
            [partitionList addObject:[data subarrayWithRange:NSMakeRange(n, partitionSize)]];
        }
        else
        {
            [partitionList addObject:[data subarrayWithRange:NSMakeRange(n, remainingSize)]];
            break;
        }
    }

    //-------------------------------------------------------------------
    // Count how many of the entries in each partition are actually on
    //-------------------------------------------------------------------
    CGFloat hoursInDay = 24; // One day

    for (NSArray *dayPartition in partitionList)
    {
        NSUInteger stageOnCount = 0;

        //-------------------------------------------------------------------
        // 1 signifies on, 0 off
        //-------------------------------------------------------------------
        for (NSNumber *status in dayPartition)
        {
            stageOnCount += [status integerValue];
        }

        //-------------------------------------------------------------------
        // Convert the number of stages on to the amount of hours each day.
        //
        // total = (24 hours) * (stagesOn / AllStagePoints)
        //
        // This value becomes more accurate with more data points in the original list.
        //-------------------------------------------------------------------
        CGFloat onOffRatio = (CGFloat)stageOnCount / [dayPartition count];

        [totals addObject:@(hoursInDay * onOffRatio)];
    }
    
    return totals;
}

#pragma mark - Day View

- (NSString *)plotKeyForIdentifier:(SCUClimateHistoryDayPlotType)type
{
    NSString *key = nil;

    switch (type)
    {
        case SCUClimateHistoryDayPlotType_HeatPoint:
            key = SAVClimateHistory_Heat_Point;
            break;
        case SCUClimateHistoryDayPlotType_CoolPoint:
            key = SAVClimateHistory_Cool_Point;
            break;
        case SCUClimateHistoryDayPlotType_IndoorTemp:
            key = SAVClimateHistory_Temp_Indoor;
            break;
        case SCUClimateHistoryDayPlotType_Heating:
            key = SAVClimateHistory_Heat_Stage_1;
            break;
        case SCUClimateHistoryDayPlotType_Cooling:
            key = SAVClimateHistory_Cool_Stage_1;
            break;
        case SCUClimateHistoryDayPlotType_FanOn:
            key = SAVClimateHistory_Fan_Relay;
            break;
        case SCUClimateHistoryDayPlotType_Humidity:
            key = SAVClimateHistory_Humidity_Indoor;
            break;
    }

    return key;
}

#pragma mark - SCUGraph Data Source

- (NSUInteger)numberOfVerticalValuesInGraph:(SCUGraph *)graph
{
    return [self.plotDataSource[[self plotKeyForIdentifier:graph.identifer]] count];
}

- (CGFloat)graph:(SCUGraph *)graph verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex
{
    return [self.plotDataSource[[self plotKeyForIdentifier:graph.identifer]][horizontalIndex] floatValue];
}

#pragma mark - Results Delegate

- (void)disRequestDidCompleteWithResults:(SAVDISResults *)results
{
    if ([results.request isEqualToString:@"fetchStageHistory"])
    {
        [self receivedStageDataUpdate:results.results];
    }
    else if ([results.request isEqualToString:@"fetchHvacHistory"])
    {
        [self receivedAllHistoryUpdate:results.results];
    }
}

@end
