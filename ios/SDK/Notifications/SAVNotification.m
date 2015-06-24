//
//  SAVNotification.m
//  SavantControl
//
//  Created by Cameron Pulsford on 1/14/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

#import "SAVNotification.h"
@import Extensions;

//-------------------------------------------------------------------
// Top Level Keys
//-------------------------------------------------------------------
static NSString *const SAVNotificationDeliveryMethodsKey     = @"delivery";
static NSString *const SAVNotificationEnabledKey      = @"enabled";
static NSString *const SAVNotificationRuleKey         = @"rule";
static NSString *const SAVNotificationIdentifierKey   = @"id";

//-------------------------------------------------------------------
// Delivery Keys
//-------------------------------------------------------------------
static NSString *const SAVNotificationDeliverySMSKey   = @"sms";
static NSString *const SAVNotificationDeliveryEmailKey = @"email";
static NSString *const SAVNotificationDeliveryPushKey  = @"push";

//-------------------------------------------------------------------
// Rule Keys
//-------------------------------------------------------------------
static NSString *const SAVNotificationRoomsKey        = @"rooms";
static NSString *const SAVNotificationZonesKey        = @"zones";

static NSString *const SAVNotificationsTriggerValuesKey     = @"trigger_values";
static NSString *const SAVNotificationsTriggerComparisonKey = @"trigger_comparison";

static NSString *const SAVNotificationServiceKey      = @"service";
static NSString *const SAVNotificationTypeKey         = @"type";

static NSString *const SAVNotificationScheduleKey     = @"schedule";

//-------------------------------------------------------------------
// Scheduling Keys
//-------------------------------------------------------------------
static NSString *const SAVNotificationDateRangeKey    = @"activeDateRange";
static NSString *const SAVNotificationStartMonthKey   = @"startMonth";
static NSString *const SAVNotificationEndMonthKey     = @"endMonth";
static NSString *const SAVNotificationStartDateKey    = @"startDate";
static NSString *const SAVNotificationEndDateKey      = @"endDate";

static NSString *const SAVNotificationDaysKey         = @"scheduledDays";
static NSString *const SAVNotificationTimeKey         = @"scheduledTime";
static NSString *const SAVNotificationEndTimeKey      = @"scheduledEndTime";

static NSString *const SAVNotificationScheduleTypeKey = @"type";

static NSString *const SAVNotificationCelestialReferenceStartKey = @"celestialReference";
static NSString *const SAVNotificationCelestialReferenceEndKey   = @"celestialEndReference";

static NSString *const SAVNotificationStartOffsetKey             = @"startOffset";
static NSString *const SAVNotificationEndOffsetKey               = @"endOffset";

//-------------------------------------------------------------------
// Strings
//-------------------------------------------------------------------
static NSString *const SAVNotificationDawn                  = @"dawn";
static NSString *const SAVNotificationDusk                  = @"dusk";
static NSString *const SAVNotificationSunrise               = @"sunrise";
static NSString *const SAVNotificationSunset                = @"sunset";

static NSString *const SAVNotificationEntertainment = @"entertainment";
static NSString *const SAVNotificationLighting      = @"lighting";
static NSString *const SAVNotificationTemperature   = @"temperature";
static NSString *const SAVNotificationHumidity      = @"humidity";

static NSString *const SAVNotificationScheduleCelestial  = @"celestial";
static NSString *const SAVNotificationScheduleNormal     = @"normal";

@interface SAVNotification ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, getter = isScheduled) BOOL scheduled;
@property (nonatomic, getter = isAllYear) BOOL allYear;
@property (nonatomic, getter = isAllDay) BOOL allDay;

@end

@implementation SAVNotification

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.startDate = [[NSDate alloc] init];
        self.endDate = [[NSDate alloc] init];
        [self applySettings:dictionary];
    }

    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.startDate = [[NSDate alloc] init];
        self.endDate = [[NSDate alloc] init];
        self.pushDeliveryEnabled = YES;
        self.enabled = YES;
        self.time = -1;
        self.endTime = -1;
        self.startOffset = 0;
        self.endOffset = 0;
        self.serviceType = SAVNotificationServiceTypeLighting;
        self.days = [@[@(SAVNotificationDay_Monday),@(SAVNotificationDay_Tuesday),@(SAVNotificationDay_Wednesday),@(SAVNotificationDay_Thursday),@(SAVNotificationDay_Friday),@(SAVNotificationDay_Saturday),@(SAVNotificationDay_Sunday)] mutableCopy];
        self.scheduleType = SAVNotificationScheduleType_Normal;
    }
    
    return self;
}

- (void)applySettings:(NSDictionary *)settings
{
    if (settings[SAVNotificationIdentifierKey])
    {
        self.identifier = settings[SAVNotificationIdentifierKey];
    }
    
    self.enabled = [settings[SAVNotificationEnabledKey] boolValue];
    
    if (settings[SAVNotificationDeliveryMethodsKey])
    {
        NSDictionary *deliveryMethods = settings[SAVNotificationDeliveryMethodsKey];
        
        self.pushDeliveryEnabled = [deliveryMethods[SAVNotificationDeliveryPushKey] boolValue];
        self.smsDeliveryEnabled = [deliveryMethods[SAVNotificationDeliverySMSKey] boolValue];
        self.emailDeliveryEnabled = [deliveryMethods[SAVNotificationDeliveryEmailKey] boolValue];
    }
    
    if (settings[SAVNotificationRuleKey])
    {
        NSDictionary *rule = settings[SAVNotificationRuleKey];
        
        self.rooms = rule[SAVNotificationRoomsKey];
        self.zones = rule[SAVNotificationZonesKey];
        
        self.triggerValues = rule[SAVNotificationsTriggerValuesKey];
        self.triggerComparison = rule[SAVNotificationsTriggerComparisonKey];
        
        self.service = rule[SAVNotificationServiceKey];
        
        NSString *serviceType = rule[SAVNotificationTypeKey];
        
        if ([serviceType isEqualToString:SAVNotificationEntertainment])
        {
            self.serviceType = SAVNotificationServiceTypeEntertainment;
        }
        
        else if ([serviceType isEqualToString:SAVNotificationHumidity])
        {
            self.serviceType = SAVNotificationServiceTypeHumidity;
        }
        
        else if ([serviceType isEqualToString:SAVNotificationLighting])
        {
            self.serviceType = SAVNotificationServiceTypeLighting;
        }
        
        else if ([serviceType isEqualToString:SAVNotificationTemperature])
        {
            self.serviceType = SAVNotificationServiceTypeTemperature;
        }
        
        if (rule[SAVNotificationScheduleKey])
        {
            NSDictionary *schedule = rule[SAVNotificationScheduleKey];
            
            if (schedule[SAVNotificationDateRangeKey])
            {
                NSDictionary *dateRange = schedule[SAVNotificationDateRangeKey];
                
                self.dateFormatter.dateFormat = @"MM/dd";

                if ([dateRange.allKeys count] > 0)
                {
                    self.startDate = [self.dateFormatter dateFromString:[NSString stringWithFormat:@"%@/%@", dateRange[SAVNotificationStartMonthKey], dateRange[SAVNotificationStartDateKey]]];
                    self.endDate = [self.dateFormatter dateFromString:[NSString stringWithFormat:@"%@/%@", dateRange[SAVNotificationEndMonthKey], dateRange[SAVNotificationEndDateKey]]];
                }
                else
                {
                    self.startDate = [NSDate date];
                    self.endDate = self.startDate;
                }
            }
            else
            {
                self.startDate = [NSDate date];
                self.endDate = self.startDate;
            }
            
            self.time = [schedule[SAVNotificationTimeKey] floatValue];
            self.endTime = [schedule[SAVNotificationEndTimeKey] floatValue];
            
            [self.days removeAllObjects];
            NSArray *days = schedule[SAVNotificationDaysKey];
            
            for (NSUInteger i = 0; i < [days count]; i++)
            {
                if ([days[i] boolValue])
                {
                    [self.days addObject:@(i)];
                }
            }
            
            NSString *scheduleType = schedule[SAVNotificationScheduleTypeKey];
            
            if ([scheduleType isEqualToString:SAVNotificationScheduleNormal])
            {
                self.scheduleType = SAVNotificationScheduleType_Normal;
            }
            
            else if ([scheduleType isEqualToString:SAVNotificationScheduleCelestial])
            {
                self.scheduleType = SAVNotificationScheduleType_Celestial;
            }
            
            if (self.scheduleType == SAVNotificationScheduleType_Celestial)
            {
                NSString *celestialReferenceStart = schedule[SAVNotificationCelestialReferenceStartKey];
                
                self.startOffset = [schedule[SAVNotificationStartOffsetKey] doubleValue];
                self.endOffset = [schedule[SAVNotificationEndOffsetKey] doubleValue];
            
                if ([celestialReferenceStart isEqualToString:SAVNotificationDawn])
                {
                    self.celestialReferenceStart = SAVNotificationCelestialType_Dawn;
                }
                
                else if ([celestialReferenceStart isEqualToString:SAVNotificationDusk])
                {
                    self.celestialReferenceStart = SAVNotificationCelestialType_Dusk;
                }
                
                else if ([celestialReferenceStart isEqualToString:SAVNotificationSunrise])
                {
                    self.celestialReferenceStart = SAVNotificationCelestialType_Sunrise;
                }
                
                else if ([celestialReferenceStart isEqualToString:SAVNotificationSunset])
                {
                    self.celestialReferenceStart = SAVNotificationCelestialType_Sunset;
                }
                
                NSString *celestialReferenceEnd = schedule[SAVNotificationCelestialReferenceEndKey];
                
                if ([celestialReferenceEnd isEqualToString:SAVNotificationDawn])
                {
                    self.celestialReferenceEnd = SAVNotificationCelestialType_Dawn;
                }
                
                else if ([celestialReferenceEnd isEqualToString:SAVNotificationDusk])
                {
                    self.celestialReferenceEnd = SAVNotificationCelestialType_Dusk;
                }
                
                else if ([celestialReferenceEnd isEqualToString:SAVNotificationSunrise])
                {
                    self.celestialReferenceEnd = SAVNotificationCelestialType_Sunrise;
                }
                
                else if ([celestialReferenceEnd isEqualToString:SAVNotificationSunset])
                {
                    self.celestialReferenceEnd = SAVNotificationCelestialType_Sunset;
                }
            }
        }
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    dictionary[SAVNotificationEnabledKey] = @(self.enabled);
    
    NSMutableDictionary *deliveryMethods = [[self deliveryMethodsDictionaryRepresentation] mutableCopy];
    dictionary[SAVNotificationDeliveryMethodsKey] = deliveryMethods;

    NSMutableDictionary *rule = [[self ruleDictionaryRepresentation] mutableCopy];
    dictionary[SAVNotificationRuleKey] = rule;
    
    return [dictionary copy];
}

- (NSDictionary *)deliveryMethodsDictionaryRepresentation
{
    NSMutableDictionary *deliveryMethods = [[NSMutableDictionary alloc] init];
    
    deliveryMethods[SAVNotificationDeliveryPushKey] = @(self.pushDeliveryEnabled);
    deliveryMethods[SAVNotificationDeliveryEmailKey] = @(self.emailDeliveryEnabled);
    deliveryMethods[SAVNotificationDeliverySMSKey] = @(self.smsDeliveryEnabled);
    
    return [deliveryMethods copy];
}

- (NSDictionary *)ruleDictionaryRepresentation
{
    NSMutableDictionary *rule = [[NSMutableDictionary alloc] init];

    if (self.rooms)
    {
        rule[SAVNotificationRoomsKey] = self.rooms;
    }
    
    if (self.zones)
    {
        rule[SAVNotificationZonesKey] = self.zones;
    }
    
    if (self.triggerValues)
    {
        rule[SAVNotificationsTriggerValuesKey] = self.triggerValues;
    }
    
    if (self.triggerComparison)
    {
        rule[SAVNotificationsTriggerComparisonKey] = self.triggerComparison;
    }
    
    if (self.service)
    {
        rule[SAVNotificationServiceKey] = self.service;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (self.serviceType)
    {
        case SAVNotificationServiceTypeLighting:
            rule[SAVNotificationTypeKey] = SAVNotificationLighting;
            break;
        case SAVNotificationServiceTypeTemperature:
            rule[SAVNotificationTypeKey] = SAVNotificationTemperature;
            break;
        case SAVNotificationServiceTypeHumidity:
            rule[SAVNotificationTypeKey] = SAVNotificationHumidity;
            break;
        case SAVNotificationServiceTypeEntertainment:
            rule[SAVNotificationTypeKey] = SAVNotificationEntertainment;
            
            break;
            
        default:
            break;
    }
#pragma clang diagnostic pop
    
    NSMutableDictionary *schedule = nil;

    schedule = [NSMutableDictionary dictionary];
    rule[SAVNotificationScheduleKey] = schedule;
    
    schedule[SAVNotificationTimeKey] = @(self.time);
    schedule[SAVNotificationEndTimeKey] = @(self.endTime);
    
    switch (self.scheduleType)
    {
        case SAVNotificationScheduleType_Celestial:
            schedule[SAVNotificationScheduleTypeKey] = SAVNotificationScheduleCelestial;
            break;
        case SAVNotificationScheduleType_Normal:
            schedule[SAVNotificationScheduleTypeKey] = SAVNotificationScheduleNormal;
            break;
    }
    
    if (self.scheduleType == SAVNotificationScheduleType_Celestial)
    {
        schedule[SAVNotificationStartOffsetKey] = @(self.startOffset);
        schedule[SAVNotificationEndOffsetKey] = @(self.endOffset);
        
        switch (self.celestialReferenceStart)
        {
            case SAVNotificationCelestialType_Dawn:
                schedule[SAVNotificationCelestialReferenceStartKey] = SAVNotificationDawn;
                break;
            case SAVNotificationCelestialType_Dusk:
                schedule[SAVNotificationCelestialReferenceStartKey] = SAVNotificationDusk;
                break;
            case SAVNotificationCelestialType_Sunrise:
                schedule[SAVNotificationCelestialReferenceStartKey] = SAVNotificationSunrise;
                break;
            case SAVNotificationCelestialType_Sunset:
                schedule[SAVNotificationCelestialReferenceStartKey] = SAVNotificationSunset;
                break;
        }
        switch (self.celestialReferenceEnd)
        {
            case SAVNotificationCelestialType_Dawn:
                schedule[SAVNotificationCelestialReferenceEndKey] = SAVNotificationDawn;
                break;
            case SAVNotificationCelestialType_Dusk:
                schedule[SAVNotificationCelestialReferenceEndKey] = SAVNotificationDusk;
                break;
            case SAVNotificationCelestialType_Sunrise:
                schedule[SAVNotificationCelestialReferenceEndKey] = SAVNotificationSunrise;
                break;
            case SAVNotificationCelestialType_Sunset:
                schedule[SAVNotificationCelestialReferenceEndKey] = SAVNotificationSunset;
                break;
        }
    }
    
    NSMutableArray *days = [NSMutableArray array];
    
    for (NSInteger i = 0; i < 7; i++)
    {
        if ([self.days containsObject:@(i)])
        {
            [days addObject:@"YES"];
        }
        else
        {
            [days addObject:@"NO"];
        }
    }
    
    schedule[SAVNotificationDaysKey] = days;
    
    if (!self.isAllYear)
    {
        NSMutableDictionary *dateRange = [NSMutableDictionary dictionary];
        schedule[SAVNotificationDateRangeKey] = dateRange;
        
        self.dateFormatter.dateFormat = @"dd";
        
        if (self.startDate)
        {
            dateRange[SAVNotificationStartDateKey] = [self.dateFormatter stringFromDate:self.startDate];
        }
        
        if (self.endDate)
        {
            dateRange[SAVNotificationEndDateKey] = [self.dateFormatter stringFromDate:self.endDate];
        }
        
        self.dateFormatter.dateFormat = @"MM";
        
        if (self.startDate)
        {
            dateRange[SAVNotificationStartMonthKey] = [self.dateFormatter stringFromDate:self.startDate];
        }
        
        if (self.endDate)
        {
            dateRange[SAVNotificationEndMonthKey] = [self.dateFormatter stringFromDate:self.endDate];
        }
    }
    else
    {
        NSMutableDictionary *dateRange = [NSMutableDictionary dictionary];
        schedule[SAVNotificationDateRangeKey] = dateRange;
    }
    
    return [rule copy];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SAVNotification *notification = [[[self class] alloc] init];
    
    notification.identifier = self.identifier;
    notification.pushDeliveryEnabled = self.isPushDeliveryEnabled;
    notification.smsDeliveryEnabled = self.isSmsDeliveryEnabled;
    notification.emailDeliveryEnabled = self.isEmailDeliveryEnabled;
    notification.enabled = self.isEnabled;
    notification.service = self.service;
    notification.rooms = [self.rooms mutableCopy];
    notification.zones = [self.zones mutableCopy];
    notification.serviceType = self.serviceType;
    notification.triggerValues = [self.triggerValues mutableCopy];
    notification.triggerComparison = self.triggerComparison;
    notification.days = [self.days mutableCopy];
    notification.time = self.time;
    notification.endTime = self.endTime;
    notification.startDate = [self.startDate copy];
    notification.endDate = [self.endDate copy];
    notification.scheduleType = self.scheduleType;
    notification.celestialReferenceStart = self.celestialReferenceStart;
    notification.celestialReferenceEnd = self.celestialReferenceEnd;
    notification.startOffset = self.startOffset;
    notification.endOffset = self.endOffset;
    
    return notification;
}

- (NSString *)dayString
{
    NSString *dayString = @"";
    
    if ([self.days count] == 7)
    {
        dayString = NSLocalizedString(@"Everyday", nil);
    }
    else if ([self.days count] == 2 && [self.days containsObject:@(SAVNotificationScheduleDay_Sunday)] && [self.days containsObject:@(SAVNotificationScheduleDay_Saturday)])
    {
        dayString = NSLocalizedString(@"Weekends", nil);
    }
    else if ([self.days count] == 5 && ![self.days containsObject:@(SAVNotificationScheduleDay_Sunday)] && ![self.days containsObject:@(SAVNotificationScheduleDay_Saturday)])
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
            
            dayString = isSingleDay ? [dayString stringByAppendingString:[self stringForDay:[day integerValue]]] : [dayString stringByAppendingString:[self shortStringForDay:[day integerValue]]];
        }
    }
    
    return dayString;
}

- (NSString *)shortStringForDay:(SAVNotificationScheduleDays)day
{
    NSString *dayString = nil;
    
    switch (day)
    {
        case SAVNotificationScheduleDay_Sunday:
            dayString = NSLocalizedString(@"Sun", nil);
            break;
        case SAVNotificationScheduleDay_Monday:
            dayString = NSLocalizedString(@"Mon", nil);
            break;
        case SAVNotificationScheduleDay_Tuesday:
            dayString = NSLocalizedString(@"Tue", nil);
            break;
        case SAVNotificationScheduleDay_Wednesday:
            dayString = NSLocalizedString(@"Wed", nil);
            break;
        case SAVNotificationScheduleDay_Thursday:
            dayString = NSLocalizedString(@"Thu", nil);
            break;
        case SAVNotificationScheduleDay_Friday:
            dayString = NSLocalizedString(@"Fri", nil);
            break;
        case SAVNotificationScheduleDay_Saturday:
            dayString = NSLocalizedString(@"Sat", nil);
            break;
    }
    return dayString;
}

- (NSString *)stringForDay:(SAVNotificationScheduleDays)day
{
    NSString *dayString = nil;
    
    switch (day)
    {
        case SAVNotificationScheduleDay_Sunday:
            dayString = NSLocalizedString(@"Sunday", nil);
            break;
        case SAVNotificationScheduleDay_Monday:
            dayString = NSLocalizedString(@"Monday", nil);
            break;
        case SAVNotificationScheduleDay_Tuesday:
            dayString = NSLocalizedString(@"Tuesday", nil);
            break;
        case SAVNotificationScheduleDay_Wednesday:
            dayString = NSLocalizedString(@"Wednesday", nil);
            break;
        case SAVNotificationScheduleDay_Thursday:
            dayString = NSLocalizedString(@"Thursday", nil);
            break;
        case SAVNotificationScheduleDay_Friday:
            dayString = NSLocalizedString(@"Friday", nil);
            break;
        case SAVNotificationScheduleDay_Saturday:
            dayString = NSLocalizedString(@"Saturday", nil);
            break;
    }
    
    return dayString;
}

- (NSString *)timeString
{
    if (self.scheduleType == SAVNotificationScheduleType_Celestial)
    {
        NSString *whenString = [NSString stringWithFormat:@"%@ and %@", self.celestialTypeStringStart, self.celestialTypeStringEnd];
//        return [NSString stringWithFormat:@"%@ %@",whenString, [self dayString]];
        return whenString;
    }
    else if ([self displaysScheduleTime])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"h:mma"];
        NSString *startString = [formatter stringFromDate:[NSDate dateWithTimeInterval:self.time sinceDate:[NSDate today]]];
        NSString *endString = [formatter stringFromDate:[NSDate dateWithTimeInterval:self.endTime sinceDate:[NSDate today]]];
        
        NSString *whenString = [NSString stringWithFormat:@"%@ and %@", startString, endString];
//        return [NSString stringWithFormat:@"%@ %@",whenString, [self dayString]];
        return whenString;
    }
    else
    {
        return @"";
    }
}

- (BOOL)displaysScheduleTime
{
    if (self.isAllDay)
    {
        return NO;
    }
    
    if (self.time == 0 && self.endTime == 0)
    {
        return NO;
    }
    
    return YES;
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
        self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"M/d"
                                                                         options:0
                                                                          locale:[NSLocale currentLocale]];
        
        dateString = [NSString stringWithFormat:@"%@ – %@", [self.dateFormatter stringFromDate:self.startDate], [self.dateFormatter stringFromDate:self.endDate]];
    }
    
    return dateString;
}

- (NSString *)scheduleTypeString
{
    NSString *typeString = nil;
    
    switch (self.scheduleType)
    {
        case SAVNotificationScheduleType_Celestial:
            typeString = NSLocalizedString(@"Relative to Celestial Time", nil);
            break;
        case SAVNotificationScheduleType_Normal:
            typeString = NSLocalizedString(@"At Time", nil);
            break;
    }
    
    return typeString;
}

- (NSString *)celestialTypeStringStart
{
    NSString *typeString = nil;
    
    switch (self.celestialReferenceStart)
    {
        case SAVNotificationCelestialType_Dawn:
            typeString = NSLocalizedString(@"Dawn", nil);
            break;
        case SAVNotificationCelestialType_Dusk:
            typeString = NSLocalizedString(@"Dusk", nil);
            break;
        case SAVNotificationCelestialType_Sunrise:
            typeString = NSLocalizedString(@"Sunrise", nil);
            break;
        case SAVNotificationCelestialType_Sunset:
            typeString = NSLocalizedString(@"Sunset", nil);
            break;
    }
    
    return typeString;
}

- (NSString *)celestialTypeStringEnd
{
    NSString *typeString = nil;
    
    switch (self.celestialReferenceEnd)
    {
        case SAVNotificationCelestialType_Dawn:
            typeString = NSLocalizedString(@"Dawn", nil);
            break;
        case SAVNotificationCelestialType_Dusk:
            typeString = NSLocalizedString(@"Dusk", nil);
            break;
        case SAVNotificationCelestialType_Sunrise:
            typeString = NSLocalizedString(@"Sunrise", nil);
            break;
        case SAVNotificationCelestialType_Sunset:
            typeString = NSLocalizedString(@"Sunset", nil);
            break;
    }
    
    return typeString;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (NSMutableArray *)zones
{
    if (!_zones)
    {
        _zones = [[NSMutableArray alloc] init];
    }
    return _zones;
}

- (NSMutableArray *)rooms
{
    if (!_rooms)
    {
        _rooms = [[NSMutableArray alloc] init];
    }
    return _rooms;
}

- (NSMutableArray *)triggerValues
{
    if (!_triggerValues)
    {
        _triggerValues = [[NSMutableArray alloc] init];
    }
    return _triggerValues;
}

- (NSMutableArray *)days
{
    if (!_days)
    {
        _days = [[NSMutableArray alloc] init];
    }
    return _days;
}

- (BOOL)isAllYear
{
    _allYear = YES;
    
    if (floor([self.startDate timeIntervalSinceReferenceDate]) != floor([self.endDate timeIntervalSinceReferenceDate]))
    {
        _allYear = NO;
    }
    
    return _allYear;
}

- (BOOL)isAllDay
{
    _allDay = YES;
    
    if ((self.time != -1) || (self.endTime != -1))
    {
        _allDay = NO;
    }
    
    else if (self.scheduleType == SAVNotificationScheduleType_Celestial)
    {
        _allDay = NO;
    }
    
    return _allDay;
}

- (BOOL)isScheduled
{
    _scheduled = NO;
    
    if ((!self.isAllDay) || (!self.isAllYear))
    {
        _scheduled = YES;
    }
    else if ([self.days count])
    {
        _scheduled = YES;
    }
    
    return _scheduled;
}

@end
