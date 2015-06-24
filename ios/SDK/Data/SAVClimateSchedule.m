//
//  SAVClimateSchedule.m
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVClimateSchedule.h"
#import <math.h>

NSString *const SAVClimateScheduleNameKey           = @"ProfileName";
NSString *const SAVClimateScheduleNameOldKey        = @"OldProfileName";
NSString *const SAVClimateScheduleActiveKey         = @"Active";
NSString *const SAVClimateScheduleDateRangeKey      = @"DateRange";
NSString *const SAVClimateScheduleDaysKey           = @"ProfileDays";
NSString *const SAVClimateScheduleZonesKey          = @"ProfileZones";
NSString *const SAVClimateScheduleProfilePointsKey  = @"ProfileSetPoints";
NSString *const SAVClimateScheduleHumidityPointsKey = @"HumidityPoints";
NSString *const SAVClimateScheduleTempPointsKey     = @"TemperaturePoints";
NSString *const SAVClimateScheduleHVACModeKey       = @"Mode";

//-------------------------------------------------------------------
// Settings Keys
//-------------------------------------------------------------------
NSString *const SAVClimateScheduleHumidityMaxKey    = @"HumidityPointMax";
NSString *const SAVClimateScheduleHumidityMinKey    = @"HumidityPointMin";
NSString *const SAVClimateScheduleHumidifyKey       = @"humidifyPoint";
NSString *const SAVClimateScheduleDeHumidifyKey     = @"dehumidifyPoint";
NSString *const SAVClimateScheduleTempMaxKey        = @"TemperaturePointMax";
NSString *const SAVClimateScheduleTempMinKey        = @"TemperaturePointMin";
NSString *const SAVClimateScheduleTempScale         = @"TemperatureScale";
NSString *const SAVClimateScheduleHumidityBufferKey = @"HumidityBuffer";
NSString *const SAVClimateScheduleTempBufferKey     = @"TemperatureBuffer";

@implementation SAVClimateSchedule

- (instancetype)initWithName:(NSString *)scheduleName
{
    self = [super init];
    if (self)
    {
        self.name = scheduleName;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVClimateSchedule *copy = [[SAVClimateSchedule alloc] init];

    if (copy)
    {
        copy.temperatureMaxPoint = self.temperatureMaxPoint;
        copy.temperatureMinPoint = self.temperatureMinPoint;
        copy.humidityMaxPoint = self.humidityMaxPoint;
        copy.humidityMinPoint = self.humidityMinPoint;
        copy.humidityPointBuffer = self.humidityPointBuffer;
        copy.temperaturePointBuffer = self.temperaturePointBuffer;
        copy.scale = self.scale;
        [copy applySettings:self.dictionaryRepresentation];
        [copy applyGlobalSettings:self.dictionaryRepresentation];
    }

    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, %@, %@", self.name, [self shortDateString], [self dayString]];
}

- (CGFloat)humidityRange
{
    return self.humidityMaxPoint - self.humidityMinPoint;
}

- (CGFloat)temperatureRange
{
    return self.temperatureMaxPoint - self.temperatureMinPoint;
}

- (BOOL)isAllYear
{
    return [self.dateRange count] ? NO : YES;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:self.name forKey:SAVClimateScheduleNameKey];
    [dictionary setValue:self.oldName forKey:SAVClimateScheduleNameOldKey];

    if (!self.isAllYear)
    {
        [dictionary setValue:self.dateRange forKey:SAVClimateScheduleDateRangeKey];
    }

    [dictionary setValue:@(self.isActive) forKey:SAVClimateScheduleActiveKey];
    [dictionary setValue:self.days forKey:SAVClimateScheduleDaysKey];
    [dictionary setValue:self.zones forKey:SAVClimateScheduleZonesKey];

    NSMutableDictionary *scheduleSetPoints = [NSMutableDictionary dictionary];
    [dictionary setValue:[SAVClimateSchedule stringForHVACMode:self.hvacMode] forKey:SAVClimateScheduleHVACModeKey];

    if ([self.humiditySetPoints count])
    {
        NSMutableArray *humidityPoints = [NSMutableArray array];

        for (SAVClimateSetPoint *setPoint in self.humiditySetPoints)
        {
            NSDictionary *setPointDictionary = [setPoint dictionaryRepresentation];
            if (setPointDictionary[SAVClimateScheduleHumidifyKey] || setPointDictionary[SAVClimateScheduleDeHumidifyKey])
            {
                self.humidityType = SAVClimateSetPointType_HumidifyDehumidify;
            }
            else
            {
                self.humidityType = SAVClimateSetPointType_Humidity;
            }
            
            setPoint.type = self.humidityType;
            [humidityPoints addObject:[setPoint dictionaryRepresentation]];
        }

        scheduleSetPoints[SAVClimateScheduleHumidityPointsKey] = humidityPoints;
    }
    else
    {
        scheduleSetPoints[SAVClimateScheduleHumidityPointsKey] = @[];
    }

    if ([self.temperatureSetPoints count])
    {
        NSMutableArray *temperaturePoints = [NSMutableArray array];

        for (SAVClimateSetPoint *setPoint in self.temperatureSetPoints)
        {
            setPoint.type = SAVClimateSetPointType_Temperature;
            [temperaturePoints addObject:[setPoint dictionaryRepresentation]];
        }

        scheduleSetPoints[SAVClimateScheduleTempPointsKey] = temperaturePoints;
    }
    else
    {
        scheduleSetPoints[SAVClimateScheduleTempPointsKey] = @[];
    }

    [dictionary setObject:scheduleSetPoints forKey:SAVClimateScheduleProfilePointsKey];

    return dictionary;
}

- (NSString *)dayString
{
    NSString *dayString = @"";

    if ([self.days count] == 7)
    {
        dayString = NSLocalizedString(@"Everyday", nil);
    }
    else if ([self.days count] == 2 && [self.days containsObject:@(SAVClimateScheduleDay_Sunday)] && [self.days containsObject:@(SAVClimateScheduleDay_Saturday)])
    {
        dayString = NSLocalizedString(@"Weekends", nil);
    }
    else if ([self.days count] == 5 && ![self.days containsObject:@(SAVClimateScheduleDay_Sunday)] && ![self.days containsObject:@(SAVClimateScheduleDay_Saturday)])
    {
        dayString = NSLocalizedString(@"Weekdays", nil);
    }
    else
    {
        BOOL isSingleDay = [self.days count] == 1;

        for (NSNumber *day in self.days)
        {
            if ([dayString length])
            {
                dayString = [dayString stringByAppendingString:@", "];
            }

            dayString = isSingleDay ? [dayString stringByAppendingString:[SAVClimateSchedule stringForDay:[day integerValue]]] : [dayString stringByAppendingString:[SAVClimateSchedule shortStringForDay:[day integerValue]]];
        }
    }

    return dayString;
}

- (NSString *)shortDateString
{
    NSString *dateString = @"";
    
    if (self.isAllYear)
    {
        dateString = NSLocalizedString(@"All Year", nil);
    }
    else
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yyyy hh:mm:ss";
        
        NSDate *startDate   = [df dateFromString:self.dateRange[@"startDate"]];
        NSDate *endDate = [df dateFromString:self.dateRange[@"endDate"]];
        
        df.dateFormat = @"M/d";
        
        dateString = [NSString stringWithFormat:@"%@ – %@", [df stringFromDate:startDate], [df stringFromDate:endDate]];
    }
    
    return dateString;
}

- (NSString *)dateString
{
    NSString *dateString = @"";

    if (self.isAllYear)
    {
        dateString = NSLocalizedString(@"All Year", nil);
    }
    else
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yyyy hh:mm:ss";
        
        NSString *startDate   = self.dateRange[@"startDate"];
        NSString *endDate = self.dateRange[@"endDate"];

        dateString = [NSString stringWithFormat:@"%@ – %@", startDate, endDate];
    }

    return dateString;
}

- (void)applyGlobalSettings:(NSDictionary *)settings
{
    if (settings[SAVClimateScheduleTempMaxKey])
    {
        self.temperatureMaxPoint = [settings[SAVClimateScheduleTempMaxKey] floatValue];
    }

    if (settings[SAVClimateScheduleTempMinKey])
    {
        self.temperatureMinPoint = [settings[SAVClimateScheduleTempMinKey] floatValue];
    }

    if (settings[SAVClimateScheduleTempBufferKey])
    {
        self.temperaturePointBuffer = [settings[SAVClimateScheduleTempBufferKey] integerValue];
    }

    if (settings[SAVClimateScheduleHumidityMaxKey])
    {
        self.humidityMaxPoint = [settings[SAVClimateScheduleHumidityMaxKey] floatValue];
    }

    if (settings[SAVClimateScheduleHumidityMinKey])
    {
        self.humidityMinPoint = [settings[SAVClimateScheduleHumidityMinKey] floatValue];
    }

    if (settings[SAVClimateScheduleHumidityBufferKey])
    {
        self.humidityPointBuffer = [settings[SAVClimateScheduleHumidityBufferKey] integerValue];
    }
}

- (void)applySettings:(NSDictionary *)settings
{
    if (settings[SAVClimateScheduleNameKey])
    {
        self.name = settings[SAVClimateScheduleNameKey];
        self.oldName = nil;
    }
    
    if (settings[SAVClimateScheduleActiveKey])
    {
        self.active = [settings[SAVClimateScheduleActiveKey] boolValue];
    }
    
    if ([settings[SAVClimateScheduleDateRangeKey] count])
    {
        self.dateRange = settings[SAVClimateScheduleDateRangeKey];
    }
    else
    {
        self.dateRange = nil;
    }
    
    if (settings[SAVClimateScheduleDaysKey])
    {
        self.days = settings[SAVClimateScheduleDaysKey];
    }
    
    if (settings[SAVClimateScheduleZonesKey])
    {
        self.zones = settings[SAVClimateScheduleZonesKey];
    }
    
    if (settings[SAVClimateScheduleHVACModeKey])
    {
        self.hvacMode = [SAVClimateSchedule hvacModeFromString:settings[SAVClimateScheduleHVACModeKey]];
    }
    
    if (settings[SAVClimateScheduleProfilePointsKey])
    {
        NSDictionary *profilePoints = settings[SAVClimateScheduleProfilePointsKey];
        
        if (profilePoints[SAVClimateScheduleTempPointsKey])
        {
            NSMutableArray *tempSetPoints = [NSMutableArray array];
            
            for (NSDictionary *setPoint in profilePoints[SAVClimateScheduleTempPointsKey])
            {
                [tempSetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:setPoint minPoint:self.temperatureMinPoint buffer:self.temperaturePointBuffer andRange:self.temperatureRange andType:SAVClimateSetPointType_Temperature]];
            }
            
            self.temperatureSetPoints = tempSetPoints;
        }
        
        if (profilePoints[SAVClimateScheduleHumidityPointsKey])
        {
            NSMutableArray *humiditySetPoints = [NSMutableArray array];
            
            for (NSDictionary *setPoint in profilePoints[SAVClimateScheduleHumidityPointsKey])
            {
                self.humidityType = (setPoint[SAVClimateScheduleDeHumidifyKey] || setPoint[SAVClimateScheduleHumidifyKey]) ? SAVClimateSetPointType_HumidifyDehumidify : SAVClimateSetPointType_Humidity;
                [humiditySetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:setPoint minPoint:self.humidityMinPoint buffer:self.humidityPointBuffer andRange:self.humidityRange andType:self.humidityType]];
            }
            
            self.humiditySetPoints = humiditySetPoints;
        }
    }
}

+ (NSString *)stringForHVACMode:(SAVClimateScheduleMode)mode
{
    NSString *string = nil;

    switch (mode)
    {
        case SAVClimateScheduleMode_Auto:
            string = @"Auto";
            break;
        case SAVClimateScheduleMode_Heat:
            string = @"Heat";
            break;
        case SAVClimateScheduleMode_Cool:
            string = @"Cool";
            break;
        case SAVClimateScheduleMode_Unknown:
            break;
    }

    return string;
}

+ (NSString *)stringForDay:(SAVClimateScheduleDay)day
{
    NSString *dayString = nil;

    switch (day)
    {
        case SAVClimateScheduleDay_Sunday:
            dayString = NSLocalizedString(@"Sunday", nil);
            break;
        case SAVClimateScheduleDay_Monday:
            dayString = NSLocalizedString(@"Monday", nil);
            break;
        case SAVClimateScheduleDay_Tuesday:
            dayString = NSLocalizedString(@"Tuesday", nil);
            break;
        case SAVClimateScheduleDay_Wednesday:
            dayString = NSLocalizedString(@"Wednesday", nil);
            break;
        case SAVClimateScheduleDay_Thursday:
            dayString = NSLocalizedString(@"Thursday", nil);
            break;
        case SAVClimateScheduleDay_Friday:
            dayString = NSLocalizedString(@"Friday", nil);
            break;
        case SAVClimateScheduleDay_Saturday:
            dayString = NSLocalizedString(@"Saturday", nil);
            break;
    }

    return dayString;
}

+ (NSString *)shortStringForDay:(SAVClimateScheduleDay)day
{
    NSString *dayString = nil;

    switch (day)
    {
        case SAVClimateScheduleDay_Sunday:
            dayString = NSLocalizedString(@"Sun", nil);
            break;
        case SAVClimateScheduleDay_Monday:
            dayString = NSLocalizedString(@"Mon", nil);
            break;
        case SAVClimateScheduleDay_Tuesday:
            dayString = NSLocalizedString(@"Tue", nil);
            break;
        case SAVClimateScheduleDay_Wednesday:
            dayString = NSLocalizedString(@"Wed", nil);
            break;
        case SAVClimateScheduleDay_Thursday:
            dayString = NSLocalizedString(@"Thu", nil);
            break;
        case SAVClimateScheduleDay_Friday:
            dayString = NSLocalizedString(@"Fri", nil);
            break;
        case SAVClimateScheduleDay_Saturday:
            dayString = NSLocalizedString(@"Sat", nil);
            break;
    }

    return dayString;
}

+ (SAVClimateScheduleMode)hvacModeFromString:(NSString *)mode
{
    SAVClimateScheduleMode modeType = SAVClimateScheduleMode_Unknown;
    mode = [mode lowercaseString];

    if ([mode isEqualToString:@"auto"])
    {
        modeType = SAVClimateScheduleMode_Auto;
    }
    else if ([mode isEqualToString:@"cool"])
    {
        modeType = SAVClimateScheduleMode_Cool;
    }
    else if ([mode isEqualToString:@"heat"])
    {
        modeType = SAVClimateScheduleMode_Heat;
    }

    return modeType;
}

#pragma mark - Demo Schedules

+ (SAVClimateSchedule *)demoScheduleWithName:(NSString *)name
{
    SAVClimateSchedule *schedule = [[SAVClimateSchedule alloc] initWithName:name];

    [schedule applyDemoValues];

    return schedule;
}

- (void)applyDemoValues
{
    self.days = @[@(SAVClimateScheduleDay_Sunday),
                  @(SAVClimateScheduleDay_Monday),
                  @(SAVClimateScheduleDay_Tuesday),
                  @(SAVClimateScheduleDay_Wednesday),
                  @(SAVClimateScheduleDay_Thursday),
                  @(SAVClimateScheduleDay_Friday),
                  @(SAVClimateScheduleDay_Saturday)];
    self.zones = @[@"Second Floor", @"Main Floor"];
    self.humidityMaxPoint = 80;
    self.humidityMinPoint = 20;
    self.temperatureMaxPoint = 95;
    self.temperatureMinPoint = 45;
    self.scale = SAVClimateScheduleScale_Farenheit;
    self.temperaturePointBuffer = 5;
    self.humidityPointBuffer = 5;
    self.hvacMode = SAVClimateScheduleMode_Auto;
    self.humidityType = SAVClimateSetPointType_Humidity;

    NSMutableArray *humiditySetPoints = [NSMutableArray array];
    [humiditySetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"humidityPoint" : @"0.2",
                                                                                @"time": @"00:00:00"}
                                                                     minPoint:self.humidityMinPoint
                                                                       buffer:self.humidityPointBuffer
                                                                     andRange:self.humidityRange
                                                                      andType:self.humidityType]];
    
    [humiditySetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"humidityPoint" : @"0.2",
                                                                                @"time": @"06:00:00"}
                                                                     minPoint:self.humidityMinPoint
                                                                       buffer:self.humidityPointBuffer
                                                                     andRange:self.humidityRange
                                                                      andType:self.humidityType]];
    
    [humiditySetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"humidityPoint" : @"0.2",
                                                                                @"time": @"12:00:00"}
                                                                     minPoint:self.humidityMinPoint
                                                                       buffer:self.humidityPointBuffer
                                                                     andRange:self.humidityRange
                                                                      andType:self.humidityType]];
    
    [humiditySetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"humidityPoint" : @"0.2",
                                                                                @"time": @"18:00:00"}
                                                                     minPoint:self.humidityMinPoint
                                                                       buffer:self.humidityPointBuffer
                                                                     andRange:self.humidityRange
                                                                      andType:self.humidityType]];
    
    self.humiditySetPoints = humiditySetPoints;
    
    NSMutableArray *temperatureSetPoints = [NSMutableArray array];
    [temperatureSetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"time": @"00:00:00",
                                                                                   @"coolPoint" : @"0.85",
                                                                                   @"heatPoint" : @"0.7",
                                                                                   @"Y" : @[@"55", @"90"]}
                                                                        minPoint:60
                                                                          buffer:5
                                                                        andRange:self.temperatureRange
                                                                         andType:SAVClimateSetPointType_Temperature]];
    
    [temperatureSetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"coolPoint" : @"0.85",
                                                                                   @"heatPoint" : @"0.7",
                                                                                   @"Y" : @[@"55", @"90"],
                                                                                   @"time": @"06:00:00"}
                                                                        minPoint:60
                                                                          buffer:5
                                                                        andRange:self.temperatureRange
                                                                         andType:SAVClimateSetPointType_Temperature]];
    
    [temperatureSetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"coolPoint" : @"0.85",
                                                                                   @"heatPoint" : @"0.7",
                                                                                   @"Y" : @[@"55", @"90"],
                                                                                   @"time": @"12:00:00"}
                                                                        minPoint:60
                                                                          buffer:5
                                                                        andRange:self.temperatureRange
                                                                         andType:SAVClimateSetPointType_Temperature]];
    
    [temperatureSetPoints addObject:[[SAVClimateSetPoint alloc] initWithSettings:@{@"coolPoint" : @"0.85",
                                                                                   @"heatPoint" : @"0.7",
                                                                                   @"Y" : @[@"55", @"90"],
                                                                                   @"time": @"18:00:00"}
                                                                        minPoint:60
                                                                          buffer:5
                                                                        andRange:self.temperatureRange
                                                                         andType:SAVClimateSetPointType_Temperature]];
    
    self.temperatureSetPoints = temperatureSetPoints;
}

@end

static NSString *const SAVClimateSetPointTimeKey        = @"time";
static NSString *const SAVClimateSetPointCoolKey        = @"coolPoint";
static NSString *const SAVClimateSetPointHeatKey        = @"heatPoint";
static NSString *const SAVClimateSetPointDehumidifyKey  = @"dehumidifyPoint";
static NSString *const SAVClimateSetPointHumidifyKey    = @"humidifyPoint";
static NSString *const SAVClimateSetPointHumidityKey    = @"humidityPoint";
static NSString *const SAVClimateSetPointSetPointKey    = @"Y";

@implementation SAVClimateSetPoint

- (instancetype)initWithSettings:(NSDictionary *)settings minPoint:(CGFloat)minPoint buffer:(CGFloat)buffer andRange:(CGFloat)range andType:(SAVClimateSetPointType)type
{
    self = [super init];
    if (self)
    {
        self.minPoint = minPoint;
        self.buffer = buffer;
        self.range  = range;
        self.type = type;
        
        switch (type)
        {
            case SAVClimateSetPointType_Humidity:
                self.point2 = [settings[SAVClimateSetPointHumidityKey] floatValue];
                break;
            case SAVClimateSetPointType_HumidifyDehumidify:
                self.point2 = [settings[SAVClimateSetPointHumidifyKey] floatValue];
                self.point1 = [settings[SAVClimateSetPointDehumidifyKey] floatValue];
                break;
            case SAVClimateSetPointType_Temperature:
                self.point2 = [settings[SAVClimateSetPointHeatKey] floatValue];
                self.point1 = [settings[SAVClimateSetPointCoolKey] floatValue];
                break;
        }
        
        self.time   = settings[SAVClimateSetPointTimeKey];
    }
    
    return self;
}

- (instancetype)initWithRange:(CGFloat)range minPoint:(CGFloat)minPoint buffer:(CGFloat)buffer point1:(CGFloat)p1 point2:(CGFloat)p2 time:(NSString *)time andType:(SAVClimateSetPointType)type
{
    self = [super init];
    if (self)
    {
        self.minPoint = minPoint;
        self.buffer = buffer;
        self.range = range;
        self.type = type;
        self.point1 = (p1 - self.minPoint) / self.range;
        self.point2 = (p2 - self.minPoint) / self.range;

        if (isnan(self.point1))
        {
            self.point1 = 0;
        }

        if (isnan(self.point2))
        {
            self.point2 = 0;
        }

        self.time = time;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[SAVClimateSetPoint alloc] initWithSettings:self.dictionaryRepresentation minPoint:self.minPoint buffer:self.buffer andRange:self.range andType:self.type];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Time: %@, Point1: %f, Point2: %f", self.time, self.rawPoint1, self.rawPoint2];
}

- (CGFloat)rawPoint1
{
    return floorf((self.point1 * self.range) + self.minPoint);
}

- (void)setRawPoint1:(CGFloat)rawPoint1
{
    if (self.type == SAVClimateSetPointType_Humidity)
    {
        CGFloat point1 = (rawPoint1 - self.minPoint) / self.range;
        
        if (point1 > 1)
        {
            point1 = 1;
        }
        else if (point1 < 0)
        {
            point1 = 0;
        }
        
        self.point1 = point1;
    }
    else if (ABS(rawPoint1 - self.rawPoint2) >= self.buffer)
    {
        CGFloat point1 = (rawPoint1 - self.minPoint) / self.range;
        
        if (point1 > 1)
        {
            point1 = 1;
        }
        else if (point1 < 0)
        {
            point1 = 0;
        }
        
        self.point1 = point1;
    }
}

- (CGFloat)rawPoint2
{
    return floorf((self.point2 * self.range) + self.minPoint);
}

- (void)setRawPoint2:(CGFloat)rawPoint2
{
    if (self.type == SAVClimateSetPointType_Humidity)
    {
        CGFloat point2 = (rawPoint2 - self.minPoint) / self.range;
        
        if (point2 > 1)
        {
            point2 = 1;
        }
        else if (point2 < 0)
        {
            point2 = 0;
        }
        
        self.point2 = point2;
    }
    else if (ABS(rawPoint2 - self.rawPoint1) >= self.buffer)
    {
        CGFloat point2 = (rawPoint2 - self.minPoint) / self.range;
        
        if (point2 > 1)
        {
            point2 = 1;
        }
        else if (point2 < 0)
        {
            point2 = 0;
        }
        
        self.point2 = point2;
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    switch (self.type)
    {
        case SAVClimateSetPointType_Humidity:
            return @{SAVClimateSetPointTimeKey: self.time,
                     SAVClimateSetPointHumidityKey: @(self.point2),
                     SAVClimateSetPointSetPointKey: @[@(self.rawPoint2)]};
        
        case SAVClimateSetPointType_HumidifyDehumidify:
            return @{SAVClimateSetPointTimeKey: self.time,
                     SAVClimateSetPointDehumidifyKey: @(self.point1),
                     SAVClimateSetPointHumidifyKey: @(self.point2),
                     SAVClimateSetPointSetPointKey: @[@(self.rawPoint1), @(self.rawPoint2)]};
            
        case SAVClimateSetPointType_Temperature:
            return @{SAVClimateSetPointTimeKey: self.time,
                     SAVClimateSetPointHeatKey: @(self.point2),
                     SAVClimateSetPointCoolKey: @(self.point1),
                     SAVClimateSetPointSetPointKey: @[@(self.rawPoint1), @(self.rawPoint2)]};
    }
}

@end
