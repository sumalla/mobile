//
//  SAVHVACDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/2/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVHVACDemoRouter.h"
#import "SAVControlPrivate.h"
#import "SAVClimateSchedule.h"
#import "rpmSharedLogger.h"
#import "SAVHVACEntity.h"
#import "Savant.h"
@import Extensions;

//-------------------------------------------------------------------
// HVAC History
//-------------------------------------------------------------------
static NSString *const SAVHVACHistory_Heat_Stage_1    = @"heatStage1";
static NSString *const SAVHVACHistory_Heat_Stage_2    = @"heatStage2";
static NSString *const SAVHVACHistory_Heat_Stage_3    = @"heatStage3";
static NSString *const SAVHVACHistory_Cool_Stage_1    = @"coolStage1";
static NSString *const SAVHVACHistory_Cool_Stage_2    = @"coolStage2";
static NSString *const SAVHVACHistory_Cool_Point      = @"coolPoint";
static NSString *const SAVHVACHistory_Heat_Point      = @"heatPoint";
static NSString *const SAVHVACHistory_Humidity_Indoor = @"indoorHumidity";
static NSString *const SAVHVACHistory_Fan_Relay       = @"fanRelay";
static NSString *const SAVHVACHistory_Temp_Indoor     = @"indoorTemp";
static NSString *const SAVHVACHistory_Temp_Outdoor    = @"outdoorTemp";
static NSString *const SAVHVACHistory_Date_Range      = @"dateRange";
static NSString *const SAVHVACHistory_Start_Date      = @"start";
static NSString *const SAVHVACHistory_End_Date        = @"end";


static NSString *const SAVHVACHistory_State_AllHistory   = @"HVACAllHistory";
static NSString *const SAVHVACHistory_State_StageHistory = @"HVACStageHistory";

static NSString *const SAVHVACSchedule_State_ProfileNames           = @"ProfileNames";
static NSString *const SAVHVACSchedule_State_ProfileNamesAndDates   = @"ProfileNamesAndDates";
static NSString *const SAVHVACSchedule_State_ProfileName            = @"ProfileName";
static NSString *const SAVHVACSchedule_State_ProfileProperties      = @"FetchProfileProperties";
static NSString *const SAVHVACSchedule_State_ProfilePropertiesKey   = @"ProfileProperties";
static NSString *const SAVHVACSchedule_State_SchedulerStatus        = @"CurrentSchedulerStatus";
static NSString *const SAVHVACSchedule_State_SchedulerSettings      = @"SchedulerSettings";
static NSString *const SAVHVACSchedule_State_AssignedSchedule       = @"AssignedSchedule";

@interface SAVHVACDemoRouter ()

@property NSMutableDictionary *schedules;
@property NSDictionary *globalSettings;

@property NSDictionary *entityForDeviceAndAddress;

@end

@implementation SAVHVACDemoRouter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.schedules = [NSMutableDictionary dictionary];
        self.globalSettings = @{SAVHVACSchedule_State_ProfilePropertiesKey:
                                    @{SAVClimateScheduleHumidityBufferKey: @5,
                                      SAVClimateScheduleHumidityMaxKey: @100,
                                      SAVClimateScheduleHumidityMinKey: @0,
                                      SAVClimateScheduleTempBufferKey: @5,
                                      SAVClimateScheduleTempMaxKey: @90,
                                      SAVClimateScheduleTempMinKey: @10,
                                      SAVClimateScheduleTempScale: @"Farenheit" }};
        [self generateDefaultSchedules];
        [self buildEntityMap];
    }
    return self;
}

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    BOOL shouldHandle = NO;
    BOOL isHistory = NO;
    
    id response = nil;
    
    if ([request.request isEqualToString:@"fetchStageHistory"])
    {
        response = [self fetchStageHistory];
        isHistory = YES;
    }
    else if ([request.request isEqualToString:@"fetchHvacHistory"])
    {
        response = [self fetchHVACHistory];
        isHistory = YES;
    }
    else if ([request.request isEqualToString:@"register"])
    {
        NSString *state = request.arguments[SAVMESSAGE_STATE_KEY];
        
        if ([state isEqualToString:SAVHVACSchedule_State_ProfileNamesAndDates])
        {
            response = [self fetchProfileList];
        }
        else if ([state hasSuffix:SAVHVACSchedule_State_AssignedSchedule])
        {
            NSArray *components = [state componentsSeparatedByString:@"."];
            
            if ([components count] >= 2)
            {
                SAVDISFeedback *feedback = [[SAVDISFeedback alloc] init];
                feedback.state = [components[0] stringByAppendingFormat:@".%@", SAVHVACSchedule_State_AssignedSchedule];
                feedback.value = @{SAVHVACSchedule_State_ProfileName : @"Summer"};
                response = feedback;
            }
        }
        else if ([state isEqualToString:SAVHVACSchedule_State_SchedulerSettings])
        {
            SAVDISFeedback *feedback = [[SAVDISFeedback alloc] init];
            feedback.state = SAVHVACSchedule_State_SchedulerSettings;
            feedback.value = self.globalSettings;
            response = feedback;
        }
    }
    else if ([request.request isEqualToString:@"AddProfile"])
    {
        response = [self addProfile:request.arguments];
    }
    else if ([request.request isEqualToString:@"DeleteProfile"])
    {
        response = [self removeProfile:request.arguments[SAVClimateScheduleNameKey]];
    }
    else if ([request.request isEqualToString:@"ActivateProfile"])
    {
        response = [self activateProfile:request.arguments[SAVClimateScheduleNameKey] activate:[request.arguments[SAVClimateScheduleActiveKey] boolValue]];
    }
    else if ([request.request isEqualToString:@"SaveProfileProperties"])
    {
        response = [self saveProfileProperties:request.arguments];
    }
    else if ([request.request isEqualToString:@"FetchProfileProperties"])
    {
        response = [self fetchProfileProperties:request.arguments[SAVClimateScheduleNameKey]];
    }
    
    if (response)
    {
        shouldHandle = YES;
        
        if ([response isKindOfClass:[SAVDISResults class]])
        {
            SAVDISResults *results = (SAVDISResults *)response;
            
            if (isHistory)
            {
                NSMutableDictionary *value = [NSMutableDictionary dictionaryWithDictionary:results.results];
                value[SAVHVACHistory_Date_Range] = @{SAVHVACHistory_Start_Date: request.arguments[@"startDate"],
                                                     SAVHVACHistory_End_Date: request.arguments[@"endDate"]};
                
                results.results = value;
            }
            
            results.app = request.app;
            results.request = request.request;
        }
        else if ([response isKindOfClass:[SAVDISFeedback class]])
        {
            SAVDISFeedback *feedback = (SAVDISFeedback *)response;
            feedback.app = request.app;
        }
        
        [[Savant control].demoServer sendMessage:response];
    }
    
    return shouldHandle;
}

#pragma mark - HVAC Scheduling

- (SAVDISFeedback *)activateProfile:(NSString *)name activate:(BOOL)activate
{
    SAVClimateSchedule *schedule = self.schedules[name];
    schedule.active = activate;
    
    self.schedules[name] = schedule;
    
    return [self fetchProfileList];
}

- (SAVDISFeedback *)addProfile:(NSDictionary *)settings
{
    return [self saveProfileProperties:settings];
}

- (SAVDISFeedback *)removeProfile:(NSString *)profileName
{
    [self.schedules removeObjectForKey:profileName];
    
    return [self fetchProfileList];
}

- (SAVDISFeedback *)fetchProfileList
{
    SAVDISFeedback *profileList = [[SAVDISFeedback alloc] init];
    profileList.state = SAVHVACSchedule_State_ProfileNamesAndDates;
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    
    for (SAVClimateSchedule *schedule in [self.schedules allValues])
    {
        NSMutableDictionary *scheduleData = [NSMutableDictionary dictionary];
        
        scheduleData[@"Active"] = @(schedule.isActive);
        
        if (schedule.days)
        {
            scheduleData[@"ProfileDays"] = schedule.days;
        }
        
        if (schedule.dateRange)
        {
            scheduleData[@"DateRange"] = schedule.dateRange;
        }
        
        response[schedule.name] = [scheduleData copy];
    }
    profileList.value = @{@"ProfileNamesAndDates" : response};
    
    return profileList;
}

- (SAVDISFeedback *)fetchProfileProperties:(NSString *)profileName
{
    SAVDISFeedback *profileProperties = [[SAVDISFeedback alloc] init];
    profileProperties.state = SAVHVACSchedule_State_ProfileProperties;
    profileProperties.value = [self.schedules[profileName] dictionaryRepresentation];
    
    return profileProperties;
}

- (SAVDISFeedback *)saveProfileProperties:(NSDictionary *)settings
{
    SAVClimateSchedule *schedule = nil;
    
    if (settings[SAVClimateScheduleNameOldKey])
    {
        schedule = self.schedules[settings[SAVClimateScheduleNameOldKey]];
        [self.schedules removeObjectForKey:settings[SAVClimateScheduleNameOldKey]];
    }
    else
    {
        schedule = self.schedules[settings[SAVClimateScheduleNameKey]];
    }
    
    if (!schedule)
    {
        schedule = [[SAVClimateSchedule alloc] initWithName:settings[SAVClimateScheduleNameKey]];
    }
    
    [schedule applyGlobalSettings:self.globalSettings[@"ProfileProperties"]];
    [schedule applySettings:settings];
    
    self.schedules[schedule.name] = schedule;
    
    return [self fetchProfileList];
}

- (void)generateDefaultSchedules
{
    NSArray *scheduleName = @[@"Winter", @"Summer", @"Fall", @"Spring"];
    for (NSString *name in scheduleName)
    {
        self.schedules[name] = [SAVClimateSchedule demoScheduleWithName:name];
    }
    
    for (SAVClimateSchedule *schedule in [self.schedules allValues])
    {
        if ([schedule.name isEqualToString:@"Winter"])
        {
            schedule.active = YES;
            schedule.dateRange = @{@"startDate": @"10/10/2013 00:00:00", @"endDate": @"03/24/2014 00:00:00"};
        }
        else if ([schedule.name isEqualToString:@"Summer"])
        {
            schedule.active = YES;
            schedule.dateRange = @{@"startDate": @"06/01/2014 00:01:00", @"endDate": @"08/09/2014 00:00:00"};
        }
        else if ([schedule.name isEqualToString:@"Fall"])
        {
            schedule.dateRange = @{@"startDate": @"08/09/2014 00:01:00", @"endDate": @"10/10/2014 00:00:00"};
        }
        else if ([schedule.name isEqualToString:@"Spring"])
        {
            schedule.dateRange = @{@"startDate": @"03/24/2014 00:01:00", @"endDate": @"06/1/2014 00:00:00"};
        }
    }
}

#pragma mark - HVAC History

- (SAVDISResults *)fetchStageHistory
{
    SAVDISResults *results = [[SAVDISResults alloc] init];
    
    results.results = [self buildRandomStageData:1008];
    
    return results;
}

- (SAVDISResults *)fetchHVACHistory
{
    SAVDISResults *results = [[SAVDISResults alloc] init];
    
    NSMutableDictionary *value = [[self buildSimpleStageData] mutableCopy];
    
    [value addEntriesFromDictionary:@{SAVHVACHistory_Cool_Point: [self buildCoolPointData],
                                      SAVHVACHistory_Heat_Point: [self buildHeatPointData],
                                      SAVHVACHistory_Humidity_Indoor: [self buildHumidityData],
                                      SAVHVACHistory_Fan_Relay: [self buildFanRelayData],
                                      SAVHVACHistory_Temp_Indoor: [self buildIndoorTempData],
                                      SAVHVACHistory_Temp_Outdoor: [self buildOutdoorTempData]}];
    
    results.results = value;
    
    return results;
}

#pragma mark - Data Generation

- (NSDictionary *)buildRandomStageData:(NSInteger)points
{
    NSMutableArray *heatStage1 = [NSMutableArray array];
    NSMutableArray *heatStage2 = [NSMutableArray array];
    NSMutableArray *heatStage3 = [NSMutableArray array];
    NSMutableArray *coolStage1 = [NSMutableArray array];
    NSMutableArray *coolStage2 = [NSMutableArray array];
    
    for (NSInteger i = 1; i <= points; i++)
    {
        NSInteger randomState = [self randomNumberUpto:3];
        BOOL heatState = (randomState == 1) ? YES : NO;
        BOOL coolState = (randomState == 2) ? YES : NO;
        [heatStage1 addObject:@(heatState)];
        [heatStage2 addObject:@(heatState)];
        [heatStage3 addObject:@(heatState)];
        [coolStage1 addObject:@(coolState)];
        [coolStage2 addObject:@(coolState)];
    }
    
    return @{SAVHVACHistory_Heat_Stage_1: heatStage1,
             SAVHVACHistory_Heat_Stage_2: heatStage2,
             SAVHVACHistory_Heat_Stage_3: heatStage3,
             SAVHVACHistory_Cool_Stage_1: coolStage1,
             SAVHVACHistory_Cool_Stage_2: coolStage2};
}

- (NSDictionary *)buildSimpleStageData
{
    
    NSArray *heatPoints = [self buildHeatPointData];
    NSArray *coolPoints = [self buildCoolPointData];
    NSArray *tempPoints = [self buildIndoorTempData];
    NSMutableArray *heat1 = [NSMutableArray array];
    NSMutableArray *heat2 = [NSMutableArray array];
    NSMutableArray *heat3 = [NSMutableArray array];
    NSMutableArray *cool1 = [NSMutableArray array];
    NSMutableArray *cool2 = [NSMutableArray array];
    //base on setpoints and indoor temp,
    NSInteger lastHeatPoint = 68;
    NSInteger lastCoolPoint = 72;
    NSInteger lastTempPoint = 70;
    
    for (NSUInteger i = 1; i <= 288; i++)
    {
        NSNumber *tempPoint;
        if ([heatPoints count] > i)
        {
            tempPoint = heatPoints[i];
            lastHeatPoint = [tempPoint integerValue];
            if (lastHeatPoint == 0)
            {
                lastHeatPoint = 68;
            }
        }
        if ([coolPoints count] > i)
        {
            tempPoint = coolPoints[i];
            lastCoolPoint = [tempPoint integerValue];
            if (lastCoolPoint == 0)
            {
                lastCoolPoint = 72;
            }
        }
        if ([tempPoints count] > i)
        {
            tempPoint = tempPoints[i];
            lastTempPoint = [tempPoint integerValue];
            if (lastTempPoint == 0)
            {
                lastTempPoint = 70;
            }
        }
        
        if (lastTempPoint < lastHeatPoint + 1)
        {
            [cool1 addObject:@(0)];
            [cool2 addObject:@(0)];
            [heat1 addObject:@(1)];
            
            switch (lastHeatPoint - lastTempPoint)
            {
                case 1:
                {
                    [heat2 addObject:@(0)];
                    [heat3 addObject:@(0)];
                    break;
                }
                case 2:
                {
                    [heat2 addObject:@(1)];
                    [heat3 addObject:@(0)];
                    break;
                }
                default:
                {
                    [heat2 addObject:@(1)];
                    [heat3 addObject:@(1)];
                    break;
                }
            }
        }
        else if (lastTempPoint > lastCoolPoint - 1)
        {
            [heat1 addObject:@(0)];
            [heat2 addObject:@(0)];
            [heat3 addObject:@(0)];
            [cool1 addObject:@(1)];
            switch (lastCoolPoint - lastTempPoint - 1)
            {
                case 1:
                case 2:
                {
                    [cool2 addObject:@(0)];
                    break;
                }
                default:
                {
                    [cool2 addObject:@(1)];
                    break;
                }
            }
            
            [cool2 addObject:@(1)];
        }
        else
        {
            [heat1 addObject:@(0)];
            [heat2 addObject:@(0)];
            [heat3 addObject:@(0)];
            [cool1 addObject:@(0)];
            [cool2 addObject:@(0)];
        }
    }
    
    return @{SAVHVACHistory_Heat_Stage_1: heat1,
             SAVHVACHistory_Heat_Stage_2: heat2,
             SAVHVACHistory_Heat_Stage_3: heat3,
             SAVHVACHistory_Cool_Stage_1: cool1,
             SAVHVACHistory_Cool_Stage_2: cool2};
}

- (NSArray *)buildFanRelayData
{
    //on when heating or cooling + more
    NSDictionary *stages = [self buildSimpleStageData];
    NSArray *heat_Stage_1 = stages[SAVHVACHistory_Heat_Stage_1];
    NSArray *cool_Stage_1 = stages[SAVHVACHistory_Cool_Stage_1];
    
    NSMutableArray *fanRelayData = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < 288; i++)
    {
        if (i % 15 == i % 45)
        {
            [fanRelayData addObject:@(1)];
        }
        else
        {
            BOOL fanOn = [heat_Stage_1[i] boolValue] || [cool_Stage_1[i] boolValue];
            [fanRelayData addObject:@(fanOn)];
        }
    }
    
    return fanRelayData;
}

- (NSArray *)buildHumidityData
{
    NSMutableArray *humidityData = [NSMutableArray array];
    
    for (NSInteger i = 1; i <= 288; i++)
    {
        double value = round(8 * (sin([self toRadians:(i * 2)] + cos([self toRadians:(i * 2)]))) + 55);
        
        [humidityData addObject:@((NSInteger)value)];
    }
    
    return humidityData;
}

- (NSArray *)buildIndoorTempData
{
    NSMutableArray *indoorTempData = [NSMutableArray array];
    
    for (NSInteger i = 1; i <= 288; i++)
    {
        double value = round(7 * (sin([self toRadians:(i * 3)] + cos([self toRadians:(i * 3)]))) + 68);
        
        [indoorTempData addObject:@((NSInteger)value)];
    }
    
    return indoorTempData;
}

- (NSArray *)buildOutdoorTempData
{
    NSMutableArray *outdoorTempData = [NSMutableArray array];
    
    for (NSInteger i = 1; i <= 288; i++)
    {
        double value = round(8 * (sin([self toRadians:(i * 2)] + cos([self toRadians:(i * 3)]))) + 60);
        
        [outdoorTempData addObject:@((NSUInteger)value)];
    }
    
    return outdoorTempData;
}

- (NSArray *)buildHeatPointData
{
    NSMutableArray *heatPointData = [NSMutableArray array];
    
    for (NSInteger i = 1; i <= 288; i++)
    {
        NSInteger value = 55;
        if (i < 25)
        {
            value = 55;
        }
        else if (i < 100)
        {
            value = 68;
        }
        else if (i < 125)
        {
            value = 72;
        }
        
        [heatPointData addObject:@(value)];
    }
    
    return heatPointData;
}

- (NSArray *)buildCoolPointData
{
    NSMutableArray *coolPointData = [NSMutableArray array];
    NSMutableArray *heatPointData = [[self buildHeatPointData] mutableCopy];
    
    for (NSInteger i = 0; i < 288; i++)
    {
        NSInteger value = 75;
        if (i < 35)
        {
            value = 70;
        }
        else if (i < 90)
        {
            value = 58;
        }
        else if (i < 140)
        {
            value = 68;
        }
        NSInteger coolPointBasedOnDeadBand = [heatPointData[i] integerValue] + 4;
        if (coolPointBasedOnDeadBand > value)
        {
            value = coolPointBasedOnDeadBand;
        }
        [coolPointData addObject:@(value)];
    }
    
    return coolPointData;
}

#pragma mark - Entities

- (void)buildEntityMap
{
    NSArray *entities = [[Savant data] HVACEntities:nil zone:nil service:nil];
    
    NSMutableDictionary *entityForDeviceAndAddress = [NSMutableDictionary dictionary];
    for (SAVHVACEntity *entity in entities)
    {
        //-------------------------------------------------------------------
        // Ignore entities without states as we can't do anything for them
        //-------------------------------------------------------------------
        if (entity.humiditySPCount > 0 || entity.tempSPCount > 0)
        {
            NSString *device = [NSString stringWithFormat:@"%@.%@", entity.service.component, entity.service.logicalComponent];
            NSMutableDictionary *deviceDictionary = entityForDeviceAndAddress[device];
            if (!deviceDictionary)
            {
                deviceDictionary = [NSMutableDictionary dictionary];
                entityForDeviceAndAddress[device] = deviceDictionary;
            }
            
            NSMutableArray *entityArray = deviceDictionary[entity.addresses];
            if (!entityArray)
            {
                entityArray = [NSMutableArray array];
                deviceDictionary[entity.addresses] = entityArray;
            }
            
            [entityArray addObject:entity];
        }
    }
    
    self.entityForDeviceAndAddress = entityForDeviceAndAddress;
}

- (BOOL)handleServiceRequest:(SAVServiceRequest *)request
{
    BOOL shouldHandle = NO;
    
    if ([request.serviceId isEqualToString:@"SVC_ENV_HVAC"])
    {
        NSString *scope = [NSString stringWithFormat:@"%@.%@", request.component, request.logicalComponent];
        
        if (self.entityForDeviceAndAddress[scope])
        {
            NSMutableArray *addresses = [NSMutableArray array];
            
            for (NSString *arg in [request.requestArguments sav_sortedStringKeys])
            {
                if ([arg hasPrefix:@"ThermostatAddress"])
                {
                    [addresses addObject:request.requestArguments[arg]];
                }
            }
            
            if (self.entityForDeviceAndAddress[scope][addresses])
            {
                NSMutableDictionary *states = [NSMutableDictionary dictionary];
                
                SAVEntityEvent event = [[[[[[self.entityForDeviceAndAddress allValues] lastObject] allValues] lastObject] lastObject] eventForCommand:request.request];
                NSMutableDictionary *stateTypeToValue = [NSMutableDictionary dictionary];
                
                BOOL changedHeat = NO;
                BOOL changedCool = NO;
                
                switch (event)
                {
                    case SAVEntityEvent_AutoUp:
                    case SAVEntityEvent_CoolUp:
                        changedCool = YES;
                        stateTypeToValue[@(SAVEntityState_CoolPoint)] = @"increment";
                        break;
                    case SAVEntityEvent_AutoDown:
                    case SAVEntityEvent_CoolDown:
                        changedCool = YES;
                        stateTypeToValue[@(SAVEntityState_CoolPoint)] = @"decrement";
                        break;
                    case SAVEntityEvent_CoolSet:
                        changedCool = YES;
                        if (request.requestArguments[@"CoolPointTemperature"])
                        {
                            stateTypeToValue[@(SAVEntityState_CoolPoint)] = request.requestArguments[@"CoolPointTemperature"];
                        }
                        break;
                    case SAVEntityEvent_HeatUp:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_HeatPoint)] = @"increment";
                        break;
                    case SAVEntityEvent_HeatDown:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_HeatPoint)] = @"decrement";
                        break;
                    case SAVEntityEvent_HeatSet:
                        changedHeat = YES;
                        if (request.requestArguments[@"HeatPointTemperature"])
                        {
                            stateTypeToValue[@(SAVEntityState_HeatPoint)] = request.requestArguments[@"HeatPointTemperature"];
                        }
                        break;
                    case SAVEntityEvent_HumidfyUp:
                        break;
                    case SAVEntityEvent_HumidfyDown:
                        break;
                    case SAVEntityEvent_HumidfySet:
                        //                        value = request.requestArguments[@"HumidifyPoint"];
                        break;
                    case SAVEntityEvent_DehumidfyUp:
                        break;
                    case SAVEntityEvent_DehumidfyDown:
                        break;
                    case SAVEntityEvent_DehumidfySet:
                        //                        value = request.requestArguments[@"DehumidifyPoint"];
                        break;
                    case SAVEntityEvent_SingleHumidityUp:
                    case SAVEntityEvent_HumidtyUp:
                        break;
                    case SAVEntityEvent_SingleHumidityDown:
                    case SAVEntityEvent_HumidtyDown:
                        break;
                    case SAVEntityEvent_SingleHumiditySet:
                    case SAVEntityEvent_HumidtySet:
                        //                        value = request.requestArguments[@"HumidityPoint"];
                        break;
                    case SAVEntityEvent_FanAuto:
                        stateTypeToValue[@(SAVEntityState_FanmodeAuto)] = @YES;
                        stateTypeToValue[@(SAVEntityState_FanmodeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_FanmodeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_Fanmode)] = @"Auto";
                        break;
                    case SAVEntityEvent_FanOn:
                        stateTypeToValue[@(SAVEntityState_FanmodeAuto)] = @NO;
                        stateTypeToValue[@(SAVEntityState_FanmodeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_FanmodeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_Fanmode)] = @"On";
                        break;
                    case SAVEntityEvent_FanOff:
                        stateTypeToValue[@(SAVEntityState_FanmodeAuto)] = @NO;
                        stateTypeToValue[@(SAVEntityState_FanmodeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_FanmodeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_Fanmode)] = @"Off";
                        break;
                    case SAVEntityEvent_FanSpeedAuto:
                        break;
                    case SAVEntityEvent_FanSpeedLow:
                        break;
                    case SAVEntityEvent_FanSpeedMediumLow:
                        break;
                    case SAVEntityEvent_FanSpeedMedium:
                        break;
                    case SAVEntityEvent_FanSpeedMediumHigh:
                        break;
                    case SAVEntityEvent_FanSpeedHigh:
                        break;
                    case SAVEntityEvent_ModeAuto:
                        stateTypeToValue[@(SAVEntityState_ModeHeat)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeCool)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeAuto)] = @YES;
                        stateTypeToValue[@(SAVEntityState_Mode)] = @"Auto";
                        break;
                    case SAVEntityEvent_ModeCool:
                        stateTypeToValue[@(SAVEntityState_ModeHeat)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeCool)] = @YES;
                        stateTypeToValue[@(SAVEntityState_ModeAuto)] = @NO;
                        stateTypeToValue[@(SAVEntityState_Mode)] = @"Cool";
                        break;
                    case SAVEntityEvent_ModeHeat:
                        stateTypeToValue[@(SAVEntityState_ModeHeat)] = @YES;
                        stateTypeToValue[@(SAVEntityState_ModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeCool)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeAuto)] = @NO;
                        stateTypeToValue[@(SAVEntityState_Mode)] = @"Heat";
                        break;
                    case SAVEntityEvent_ModeOff:
                        stateTypeToValue[@(SAVEntityState_ModeHeat)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_ModeCool)] = @NO;
                        stateTypeToValue[@(SAVEntityState_ModeAuto)] = @NO;
                        stateTypeToValue[@(SAVEntityState_Mode)] = @"Off";
                        break;
                    case SAVEntityEvent_ModeHumidity:
                        break;
                    case SAVEntityEvent_ModeHumidityAuto:
                        break;
                    case SAVEntityEvent_ModeHumidityOff:
                        break;
                    case SAVEntityEvent_ModeHumidify:
                        break;
                    case SAVEntityEvent_ModeDehumidify:
                        break;
                    case SAVEntityEvent_ModeACDehumidify:
                        break;
                    default:
                        RPMLogErr(@"Unexpected event type for HVAC entity %ld", (long)event);
                        break;
                }
                
                for (NSNumber *state in stateTypeToValue)
                {
                    for (SAVHVACEntity *entity in self.entityForDeviceAndAddress[scope][addresses])
                    {
                        NSString *stateString = [entity stateFromType:[state integerValue]];
                        id stateValue = stateTypeToValue[state];
                        if (stateString)
                        {
                            if ([stateValue isKindOfClass:[NSString class]])
                            {
                                if ([stateValue isEqualToString:@"increment"])
                                {
                                    stateValue = @([[Savant control].demoServer.allStates[stateString] integerValue] + 1);
                                }
                                else if ([stateValue isEqualToString:@"decrement"])
                                {
                                    stateValue = @([[Savant control].demoServer.allStates[stateString] integerValue] - 1);
                                }
                            }
                            
                            states[stateString] = stateValue;
                        }
                    }
                }
                
                if ([states count])
                {
                    for (SAVHVACEntity *entity in self.entityForDeviceAndAddress[scope][addresses])
                    {
                        // Bounds checks
                        NSString *heatPointState = [entity stateFromType:SAVEntityState_HeatPoint];
                        NSString *coolPointState = [entity stateFromType:SAVEntityState_CoolPoint];
                        NSString *coolingState = [entity stateFromType:SAVEntityState_Stage1Cooling];
                        NSString *heatingState = [entity stateFromType:SAVEntityState_Stage1Heating];
                        NSString *currentTempState = [entity stateFromType:SAVEntityState_CurrentTemp];
                        NSString *modeState = [entity stateFromType:SAVEntityState_Mode];
                        
                        NSInteger heatPoint = 0;
                        if (states[heatPointState])
                        {
                            heatPoint = [states[heatPointState] integerValue];
                        }
                        else
                        {
                            heatPoint = [[Savant control].demoServer.allStates[heatPointState] integerValue];
                        }
                        
                        NSInteger coolPoint = 0;
                        if (states[coolPointState])
                        {
                            coolPoint = [states[coolPointState] integerValue];
                        }
                        else
                        {
                            coolPoint = [[Savant control].demoServer.allStates[coolPointState] integerValue];
                        }
                        
                        NSString *mode = nil;
                        if (states[modeState])
                        {
                            mode = states[modeState];
                        }
                        else
                        {
                            mode = [Savant control].demoServer.allStates[modeState];
                        }
                        
                        NSInteger currentTemp = [[Savant control].demoServer.allStates[currentTempState] integerValue];
                        
                        if (changedCool && (heatPoint > (coolPoint - 10)))
                        {
                            states[heatPointState] = @(coolPoint - 10);
                        }
                        
                        if (changedHeat && (coolPoint < (heatPoint + 10)))
                        {
                            states[coolPointState] = @(heatPoint + 10);
                        }
                        
                        if ([mode isEqualToString:@"Auto"])
                        {
                            if (currentTemp < heatPoint)
                            {
                                states[heatingState] = @YES;
                                states[coolingState] = @NO;
                            }
                            else if (currentTemp > coolPoint)
                            {
                                states[heatingState] = @NO;
                                states[coolingState] = @YES;
                            }
                            else
                            {
                                states[heatingState] = @NO;
                                states[coolingState] = @NO;
                            }
                        }
                        else if ([mode isEqualToString:@"Cool"])
                        {
                            states[heatingState] = @NO;
                            
                            if (currentTemp > coolPoint)
                            {
                                states[coolingState] = @YES;
                            }
                            else
                            {
                                states[coolingState] = @NO;
                            }
                        }
                        else if ([mode isEqualToString:@"Heat"])
                        {
                            states[coolingState] = @NO;
                            
                            if (currentTemp < heatPoint)
                            {
                                states[heatingState] = @YES;
                            }
                            else
                            {
                                states[heatingState] = @NO;
                            }
                        }
                        else
                        {
                            states[heatingState] = @NO;
                            states[coolingState] = @NO;
                        }
                    }
                    
                    [[Savant control].demoServer sendStateUpdate:states];
                }
            }
        }
        
        shouldHandle = YES;
    }
    
    return shouldHandle;
}

#pragma mark - Helpers

- (CGFloat)toRadians:(CGFloat)degrees
{
    return degrees * (M_PI / 180);
}

- (BOOL)randomBool
{
    return arc4random_uniform(2);
}

- (NSInteger)randomNumberUpto:(NSInteger)upto
{
    return arc4random_uniform((uint32_t)upto);
}

@end
