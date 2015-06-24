//
//  SAVScene.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/22/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVScene.h"
#import "SAVClimateSchedule.h"
#import "SAVControl.h"
#import "Savant.h"
@import Extensions;

static NSString *const SAVSceneNameKey         = @"name";
static NSString *const SAVSceneIDKey           = @"id";
static NSString *const SAVSceneGlobalKey       = @"isGlobal";
static NSString *const SAVSceneActiveKey       = @"isActive";
static NSString *const SAVSceneAVKey           = @"av";
static NSString *const SAVSceneLightingKey     = @"lighting";
static NSString *const SAVSceneHVACKey         = @"hvac";
static NSString *const SAVSceneScheduleKey     = @"schedule";
static NSString *const SAVSceneIsScheduledKey  = @"isScheduled";
static NSString *const SAVSceneVolumeKey       = @"volume";
static NSString *const SAVScenePowerKey        = @"power";
static NSString *const SAVSceneRoomsKey        = @"rooms";
static NSString *const SAVSceneZonesKey        = @"zones";
static NSString *const SAVSceneLightingOffKey  = @"lightingOff";
static NSString *const SAVSceneHVACOffKey      = @"hvacOff";
static NSString *const SAVSceneAllOffKey       = @"allOff";
static NSString *const SAVSceneStatesKey       = @"states";
static NSString *const SAVSceneServiceIDKey    = @"serviceID";
static NSString *const SAVSceneMediaKey        = @"media";
static NSString *const SAVSceneDefinitionKey   = @"definition";
static NSString *const SAVSceneTagsKey         = @"tags";
static NSString *const SAVSceneCustomImageKey  = @"hasCustomImage";
static NSString *const SAVSceneImageKey        = @"imageKey";
static NSString *const SAVSceneFadeTimeKey     = @"fadeTime";

//-------------------------------------------------------------------
// Scheduling Keys
//-------------------------------------------------------------------
static NSString *const SAVSceneRepeatPeriodKey = @"repeatPeriod";
static NSString *const SAVSceneDaysKey         = @"scheduledDays";
static NSString *const SAVSceneTimeKey         = @"scheduledTime";
static NSString *const SAVSceneDateRangeKey    = @"activeDateRange";
static NSString *const SAVSceneStartMonthKey   = @"startMonth";
static NSString *const SAVSceneEndMonthKey     = @"endMonth";
static NSString *const SAVSceneStartDateKey    = @"startDate";
static NSString *const SAVSceneEndDateKey      = @"endDate";

static NSString *const SAVSceneScheduleTypeKey         = @"type";
static NSString *const SAVSceneScheduleCountdownType   = @"countdown";
static NSString *const SAVSceneScheduleCelestialType   = @"celestial";
static NSString *const SAVSceneScheduleNormalType      = @"normal";

static NSString *const SAVSceneCelestialReferenceKey = @"celestialReference";
static NSString *const SAVSceneDawn                  = @"dawn";
static NSString *const SAVSceneDusk                  = @"dusk";
static NSString *const SAVSceneSunrise               = @"sunrise";
static NSString *const SAVSceneSunset                = @"sunset";

#define kSecondsInDay 86400

@interface SAVScene ()

@property NSMutableDictionary *lightingServicesMap;
@property NSMutableDictionary *hvacServicesMap;
@property NSMutableDictionary *avServicesMap;
@property NSDateFormatter *dateFormatter;
@property id imageObserver;

@end

@implementation SAVScene

+ (SAVScene *)sceneWithSettings:(NSDictionary *)dictionary
{
    SAVScene *scene = [[SAVScene alloc] init];
    [scene applySettings:dictionary];
    return scene;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.imageSize = SAVImageSizeMedium;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.lightingServicesMap = [NSMutableDictionary dictionary];
        self.hvacServicesMap = [NSMutableDictionary dictionary];
        self.avServicesMap = [NSMutableDictionary dictionary];
        self.avPower = [NSMutableDictionary dictionary];
        self.volume = [NSMutableDictionary dictionary];
        self.lightingOff = [NSMutableArray array];
        self.hvacOff = [NSMutableArray array];
        self.days = [NSMutableArray array];
        self.tags = [NSMutableArray array];
        self.repeatPeriod = @"weekly";
        self.allYear = YES;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVScene *copy = [[SAVScene alloc] init];
    [copy applySettings:[self dictionaryRepresentation]];
    copy.wasCaptured = self.wasCaptured;
    return copy;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if (self.identifier)
    {
        dict[SAVSceneIDKey] = self.identifier;
    }

    if (self.name)
    {
        dict[SAVSceneNameKey] = self.name;
    }

    if (self.imageKey)
    {
        dict[SAVSceneImageKey] = self.imageKey;
    }

    dict[SAVSceneGlobalKey] = @(self.isGlobal);
    dict[SAVSceneActiveKey] = @(self.isActive);
    dict[SAVSceneTagsKey] = self.tags;
    dict[SAVSceneCustomImageKey] = @(self.hasCustomImage);

    NSMutableDictionary *definition = [NSMutableDictionary dictionary];
    dict[SAVSceneDefinitionKey] = definition;

    definition[SAVSceneFadeTimeKey] = @(self.fadeTime);

    NSMutableDictionary *lightingServices = [NSMutableDictionary dictionary];
    definition[SAVSceneLightingKey] = lightingServices;

    for (SAVSceneService *service in self.lightingServices)
    {
        lightingServices[service.scope] = [service dictionaryRepresentation];
    }

    NSMutableDictionary *hvacServices = [NSMutableDictionary dictionary];
    definition[SAVSceneHVACKey] = hvacServices;

    for (SAVSceneService *service in self.hvacServices)
    {
        hvacServices[service.scope] = [service dictionaryRepresentation];
    }

    NSMutableDictionary *avServices = [NSMutableDictionary dictionary];
    definition[SAVSceneAVKey] = avServices;

    for (SAVSceneService *service in self.avServices)
    {
        avServices[service.scope] = [service dictionaryRepresentation];
    }

    NSMutableDictionary *schedule = nil;
    if (self.isScheduled)
    {
        schedule = [NSMutableDictionary dictionary];
        definition[SAVSceneScheduleKey] = schedule;

        schedule[SAVSceneTimeKey] = @(self.time);
        schedule[SAVSceneRepeatPeriodKey] = self.repeatPeriod;

        switch (self.scheduleType)
        {
            case SAVSceneScheduleType_Celestial:
                schedule[SAVSceneScheduleTypeKey] = SAVSceneScheduleCelestialType;
                break;
            case SAVSceneScheduleType_Countdown:
                schedule[SAVSceneScheduleTypeKey] = SAVSceneScheduleCountdownType;
                break;
            case SAVSceneScheduleType_Normal:
                schedule[SAVSceneScheduleTypeKey] = SAVSceneScheduleNormalType;
                break;
        }

        if (self.scheduleType == SAVSceneScheduleType_Celestial)
        {
            switch (self.celestialReference)
            {
                case SAVSceneCelestialType_Dawn:
                    schedule[SAVSceneCelestialReferenceKey] = SAVSceneDawn;
                    break;
                case SAVSceneCelestialType_Dusk:
                    schedule[SAVSceneCelestialReferenceKey] = SAVSceneDusk;
                    break;
                case SAVSceneCelestialType_Sunrise:
                    schedule[SAVSceneCelestialReferenceKey] = SAVSceneSunrise;
                    break;
                case SAVSceneCelestialType_Sunset:
                    schedule[SAVSceneCelestialReferenceKey] = SAVSceneSunset;
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

        schedule[SAVSceneDaysKey] = days;

        if (!self.isAllYear)
        {
            NSMutableDictionary *dateRange = [NSMutableDictionary dictionary];
            schedule[SAVSceneDateRangeKey] = dateRange;

            self.dateFormatter.dateFormat = @"dd";

            if (self.startDate)
            {
                dateRange[SAVSceneStartDateKey] = [self.dateFormatter stringFromDate:self.startDate];
            }

            if (self.endDate)
            {
                dateRange[SAVSceneEndDateKey] = [self.dateFormatter stringFromDate:self.endDate];
            }

            self.dateFormatter.dateFormat = @"MM";

            if (self.startDate)
            {
                dateRange[SAVSceneStartMonthKey] = [self.dateFormatter stringFromDate:self.startDate];
            }

            if (self.endDate)
            {
                dateRange[SAVSceneEndMonthKey] = [self.dateFormatter stringFromDate:self.endDate];
            }
        }
    }

    if (self.volume)
    {
        definition[SAVSceneVolumeKey] = self.volume;
    }

    NSMutableDictionary *power = [NSMutableDictionary dictionary];
    definition[SAVScenePowerKey] = power;

    if (self.allOff)
    {
        power[SAVSceneAllOffKey] = @YES;
    }
    else
    {
        if ([self.avPower count])
        {
            power[SAVSceneRoomsKey] = CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)self.avPower, kCFPropertyListMutableContainers));
        }

        if ([self.lightingOff count])
        {
            power[SAVSceneLightingOffKey] = self.lightingOff;
        }

        if ([self.hvacOff count])
        {
            power[SAVSceneHVACOffKey] = self.hvacOff;
        }
    }

    return dict;
}

- (void)applySettings:(NSDictionary *)settings
{
    self.name = settings[SAVSceneNameKey];
    self.identifier = settings[SAVSceneIDKey];
    self.global = [settings[SAVSceneGlobalKey] boolValue];
    self.active = [settings[SAVSceneActiveKey] boolValue];
    self.tags = [NSMutableArray arrayWithArray:settings[SAVSceneTagsKey]];
    self.hasCustomImage = [settings[SAVSceneCustomImageKey] boolValue];
    self.imageKey = settings[SAVSceneImageKey];

    NSDictionary *definition = settings[SAVSceneDefinitionKey];

    self.fadeTime = [definition[SAVSceneFadeTimeKey] floatValue];

    self.volume = [definition[SAVSceneVolumeKey] mutableCopy];

    NSDictionary *power = definition[SAVScenePowerKey];

    if ([power[SAVSceneAllOffKey] boolValue])
    {
        self.allOff = YES;
        self.avPower = [NSMutableDictionary dictionary];
        self.hvacOff = [NSMutableArray array];
        self.lightingOff = [NSMutableArray array];
    }
    else
    {
        self.allOff = NO;
        if (power[SAVSceneRoomsKey])
        {
            self.avPower = [power[SAVSceneRoomsKey] mutableCopy];
        }
        else
        {
            [self.avPower removeAllObjects];
        }

        if (power[SAVSceneHVACOffKey])
        {
            self.hvacOff = [power[SAVSceneHVACOffKey] mutableCopy];
        }
        else
        {
            [self.hvacOff removeAllObjects];
        }

        if (power[SAVSceneLightingOffKey])
        {
            self.lightingOff = [power[SAVSceneLightingOffKey] mutableCopy];
        }
        else
        {
            [self.lightingOff removeAllObjects];
        }
    }

    [self.lightingServicesMap removeAllObjects];

    for (NSString *scope in definition[SAVSceneLightingKey])
    {
        [self addLightingSceneService:[SAVSceneService sceneServiceWithSettings:definition[SAVSceneLightingKey][scope]
                                                                      serviceID:definition[SAVSceneLightingKey][scope][SAVSceneServiceIDKey]
                                                                       andScope:scope]];
    }

    [self.hvacServicesMap removeAllObjects];

    for (NSString *scope in definition[SAVSceneHVACKey])
    {
        [self addHVACSceneService:[SAVSceneService sceneServiceWithSettings:definition[SAVSceneHVACKey][scope]
                                                                  serviceID:definition[SAVSceneHVACKey][scope][SAVSceneServiceIDKey]
                                                                   andScope:scope]];
    }

    [self.avServicesMap removeAllObjects];

    for (NSString *scope in definition[SAVSceneAVKey])
    {
        [self addAVSceneService:[SAVSceneService sceneServiceWithSettings:definition[SAVSceneAVKey][scope]
                                                                serviceID:definition[SAVSceneAVKey][scope][SAVSceneServiceIDKey]
                                                                 andScope:scope]];
    }

    if (definition[SAVSceneScheduleKey])
    {
        NSDictionary *schedule = definition[SAVSceneScheduleKey];

        self.scheduled = YES;
        self.time = [schedule[SAVSceneTimeKey] integerValue];
        self.repeatPeriod = schedule[SAVSceneRepeatPeriodKey];

        NSString *scheduleType = schedule[SAVSceneScheduleTypeKey];

        if ([scheduleType isEqualToString:SAVSceneScheduleCelestialType])
        {
            self.scheduleType = SAVSceneScheduleType_Celestial;
        }
        else if ([scheduleType isEqualToString:SAVSceneScheduleCountdownType])
        {
            self.scheduleType = SAVSceneScheduleType_Countdown;
        }
        else
        {
            self.scheduleType = SAVSceneScheduleType_Normal;
        }

        if (self.scheduleType == SAVSceneScheduleType_Celestial)
        {
            NSString *celestialReference = schedule[SAVSceneCelestialReferenceKey];

            if ([celestialReference isEqualToString:SAVSceneDawn])
            {
                self.celestialReference = SAVSceneCelestialType_Dawn;
            }
            else if ([celestialReference isEqualToString:SAVSceneDusk])
            {
                self.celestialReference = SAVSceneCelestialType_Dusk;
            }
            else if ([celestialReference isEqualToString:SAVSceneSunrise])
            {
                self.celestialReference = SAVSceneCelestialType_Sunrise;
            }
            else if ([celestialReference isEqualToString:SAVSceneSunset])
            {
                self.celestialReference = SAVSceneCelestialType_Sunset;
            }
        }

        [self.days removeAllObjects];
        NSArray *days = schedule[SAVSceneDaysKey];

        for (NSUInteger i = 0; i < [days count]; i++)
        {
            if ([days[i] boolValue])
            {
                [self.days addObject:@(i)];
            }
        }

        NSDictionary *dateRange = schedule[SAVSceneDateRangeKey];
        if ([dateRange count])
        {
            self.allYear = NO;

            self.dateFormatter.dateFormat = @"MM/dd";

            self.startDate = [self.dateFormatter dateFromString:[NSString stringWithFormat:@"%@/%@", dateRange[SAVSceneStartMonthKey], dateRange[SAVSceneStartDateKey]]];
            self.endDate = [self.dateFormatter dateFromString:[NSString stringWithFormat:@"%@/%@", dateRange[SAVSceneEndMonthKey], dateRange[SAVSceneEndDateKey]]];
        }
        else
        {
            self.allYear = YES;
        }
    }
    else
    {
        self.scheduled = NO;
    }

    if (settings[SAVSceneIsScheduledKey])
    {
        self.scheduled = [settings[SAVSceneIsScheduledKey] boolValue];
    }
}

- (void)addLightingSceneService:(SAVSceneService *)service
{
    self.lightingServicesMap[service.scope] = service;
}

- (void)removeLightingSceneService:(SAVSceneService *)service
{
    [self.lightingServicesMap removeObjectForKey:service.scope];
}

- (void)addHVACSceneService:(SAVSceneService *)service
{
    self.hvacServicesMap[service.scope] = service;
}

- (void)removeHVACSceneService:(SAVSceneService *)service
{
    [self.hvacServicesMap removeObjectForKey:service.scope];
}

- (void)addAVSceneService:(SAVSceneService *)service
{
    self.avServicesMap[service.scope] = service;
}

- (void)removeAVSceneService:(SAVSceneService *)service
{
    if (service.scope)
    {
        [self.avServicesMap removeObjectForKey:service.scope];
    }
}

- (SAVSceneService *)sceneServiceForService:(SAVService *)service
{
    SAVSceneService *sceneService = nil;

    if (service.component && service.logicalComponent && service.serviceId)
    {
        NSString *scope = [service.component stringByAppendingFormat:@".%@", service.logicalComponent];
        NSMutableDictionary *map = nil;

        if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] ||
            [service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
        {
            map = self.lightingServicesMap;
        }
        else if ([service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            map = self.hvacServicesMap;
        }
        else
        {
            map = self.avServicesMap;
        }

        sceneService = map[scope];
        sceneService.serviceID = service.serviceId;

        if (!sceneService)
        {
            sceneService = [SAVSceneService sceneServiceWithSettings:nil
                                                           serviceID:service.serviceId
                                                            andScope:scope];

            map[scope] = sceneService;
        }
    }

    return sceneService;
}

- (NSArray *)lightingServices
{
    return [self.lightingServicesMap allValues];
}

- (NSArray *)hvacServices
{
    return [self.hvacServicesMap allValues];
}

- (NSArray *)avServices
{
    return [self.avServicesMap allValues];
}

- (NSArray *)services
{
    return [[self.lightingServices arrayByAddingObjectsFromArray:self.hvacServices] arrayByAddingObjectsFromArray:self.avServices];
}

- (NSArray *)avOff
{
    NSMutableArray *avOffRooms = [NSMutableArray array];

    for (NSString *room in [self.avPower allKeys])
    {
        if (![self.avPower[room] count])
        {
            [avOffRooms addObject:room];
        }
    }

    return [avOffRooms count] ? avOffRooms : nil;
}

- (NSString *)dayString
{
    NSString *dayString = @"";

    if ([self.days count] == 7)
    {
        dayString = NSLocalizedString(@"Everyday", nil);
    }
    else if ([self.days count] == 2 && [self.days containsObject:@(SAVSceneScheduleDay_Sunday)] && [self.days containsObject:@(SAVSceneScheduleDay_Saturday)])
    {
        dayString = NSLocalizedString(@"Weekends", nil);
    }
    else if ([self.days count] == 5 && ![self.days containsObject:@(SAVSceneScheduleDay_Sunday)] && ![self.days containsObject:@(SAVSceneScheduleDay_Saturday)])
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

- (NSString *)timeString
{
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setCalendar:[NSCalendar currentCalendar]];

    self.dateFormatter.dateFormat = @"hh:mm a";

    return [self.dateFormatter stringFromDate:[NSDate dateWithTimeInterval:self.time sinceDate:[dateComponents date]]];
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
        self.dateFormatter.dateFormat = @"M/d";

        dateString = [NSString stringWithFormat:@"%@ – %@", [self.dateFormatter stringFromDate:self.startDate], [self.dateFormatter stringFromDate:self.endDate]];
    }

    return dateString;
}

- (NSString *)scheduleTypeString
{
    NSString *typeString = nil;

    switch (self.scheduleType)
    {
        case SAVSceneScheduleType_Celestial:
            typeString = NSLocalizedString(@"Relative to Celestial Time", nil);
            break;
        case SAVSceneScheduleType_Countdown:
            typeString = NSLocalizedString(@"Countdown Timer", nil);
            break;
        case SAVSceneScheduleType_Normal:
            typeString = NSLocalizedString(@"At Time", nil);
            break;
    }

    return typeString;
}

- (NSString *)celestialTypeString
{
    NSString *typeString = nil;

    switch (self.celestialReference)
    {
        case SAVSceneCelestialType_Dawn:
            typeString = NSLocalizedString(@"Dawn", nil);
            break;
        case SAVSceneCelestialType_Dusk:
            typeString = NSLocalizedString(@"Dusk", nil);
            break;
        case SAVSceneCelestialType_Sunrise:
            typeString = NSLocalizedString(@"Sunrise", nil);
            break;
        case SAVSceneCelestialType_Sunset:
            typeString = NSLocalizedString(@"Sunset", nil);
            break;
    }

    return typeString;
}

- (void)setImageKey:(NSString *)imageKey
{
    if (_imageKey != imageKey)
    {
        _imageKey = imageKey;

        [[Savant images] removeObserver:self.imageObserver];

        if (self.hasCustomImage)
        {
            SAVWeakSelf;
            self.imageObserver = [[Savant images] addObserverForKey:imageKey type:SAVImageTypeSceneImage size:self.imageSize blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                SAVStrongWeakSelf;
                sSelf.image = image;

                if (sSelf.imageChangeCallback)
                {
                    sSelf.imageChangeCallback(sSelf.image, sSelf.blurredImage);
                }
            }];

            self.imageObserver = [[Savant images] addObserverForKey:imageKey type:SAVImageTypeSceneImage size:self.imageSize blurred:YES andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                SAVStrongWeakSelf;
                sSelf.blurredImage = image;

                if (sSelf.imageChangeCallback)
                {
                    sSelf.imageChangeCallback(sSelf.image, sSelf.blurredImage);
                }
            }];
        }
        else
        {
            self.image = [UIImage sav_imageNamed:imageKey];
            
            NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"blurred-%@", imageKey] ofType:@"jpg"];
            self.blurredImage = [UIImage imageWithContentsOfFile:path];

            if (self.imageChangeCallback)
            {
                self.imageChangeCallback(self.image, self.blurredImage);
            }
        }
    }
}

#pragma mark - Service Groups

- (SAVServiceGroup *)serviceGroupForSceneService:(SAVSceneService *)sceneService
{
    NSDictionary *serviceGroups = [self serviceGroupsByIdentifier];
    SAVServiceGroup *group = nil;

    NSString *room = [sceneService.rooms firstObject];
    NSString *serviceString = [[self.avPower[room] allKeys] firstObject];

    SAVService *service = [[SAVService alloc] initWithString:serviceString];

    if (service)
    {
        group = serviceGroups[service.identifier];
    }

    return group;
}

- (NSDictionary *)serviceGroupsByIdentifier
{
    NSMutableDictionary *serviceGroupsByIdentifier = [NSMutableDictionary dictionary];

    for (NSString *room in self.avPower)
    {
        for (NSString *serviceString in self.avPower[room])
        {
            SAVService *service = [[SAVService alloc] initWithString:serviceString];

            if (service)
            {
                SAVServiceGroup *group = serviceGroupsByIdentifier[service.identifier];

                if (!group)
                {
                    group = [[SAVServiceGroup alloc] init];
                    serviceGroupsByIdentifier[service.identifier] = group;
                }

                [group addService:service];
            }
        }
    }

    return [serviceGroupsByIdentifier copy];
}

- (NSArray *)serviceGroups
{
    return [[self serviceGroupsByIdentifier] allValues];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;

    if ([_endDate timeIntervalSince1970] <= [startDate timeIntervalSince1970])
    {
        _endDate = [NSDate dateWithTimeIntervalSince1970:[startDate timeIntervalSince1970] + kSecondsInDay];
    }
}

- (void)setEndDate:(NSDate *)endDate
{
    _endDate = endDate;

    if ([_startDate timeIntervalSince1970] >= [endDate timeIntervalSince1970])
    {
        _startDate = [NSDate dateWithTimeIntervalSince1970:[endDate timeIntervalSince1970] - kSecondsInDay];
    }
}

#pragma clang diagnostic pop

@end

@interface SAVSceneService ()

@property NSMutableDictionary *settings;
@property NSMutableDictionary *combinedSettings;

@end

@implementation SAVSceneService

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.settings = [NSMutableDictionary dictionary];
        self.combinedSettings = [NSMutableDictionary dictionary];
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVSceneService *copy = [[SAVSceneService alloc] init];
    [copy applySettings:[self dictionaryRepresentation]];
    copy.serviceID = [self.serviceID copy];
    copy.component = [self.component copy];
    copy.logicalComponent = [self.logicalComponent copy];
    return copy;
}

- (NSDictionary *)states
{
    return self.settings;
}

- (NSDictionary *)combinedStates
{
    return self.combinedSettings;
}

+ (SAVSceneService *)sceneServiceWithSettings:(NSDictionary *)settings serviceID:(NSString *)serviceID andScope:(NSString *)scope
{
    NSParameterAssert(serviceID);
    NSParameterAssert(scope);

    SAVSceneService *service = [[SAVSceneService alloc] init];

    NSArray *scopeComponents = [scope componentsSeparatedByString:@"."];

    if ([scopeComponents count] == 2)
    {
        service.logicalComponent = scopeComponents[1];
        service.component = scopeComponents[0];
    }

    service.serviceID = serviceID;

    [service applySettings:settings];

    return service;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:@{SAVSceneServiceIDKey: self.serviceID}];

    if ([self.rooms count])
    {
        dictionary[SAVSceneRoomsKey] = self.rooms;
    }

    if ([self.zones count])
    {
        dictionary[SAVSceneZonesKey] = self.zones;
    }

    if ([self.states count])
    {
        dictionary[SAVSceneStatesKey] = self.states;
    }

    if ([self.mediaNode count])
    {
        dictionary[SAVSceneMediaKey] = self.mediaNode;
    }

    return dictionary;
}

- (void)applySettings:(NSDictionary *)settings
{
    self.rooms = [NSMutableArray arrayWithArray:settings[SAVSceneRoomsKey]];
    self.zones = [NSMutableArray arrayWithArray:settings[SAVSceneZonesKey]];
    self.settings = [NSMutableDictionary dictionaryWithDictionary:settings[SAVSceneStatesKey]];
    self.mediaNode = [NSMutableDictionary dictionaryWithDictionary:settings[SAVSceneMediaKey]];
    self.combinedSettings = [[self.settings copy] mutableCopy];
}

- (SAVService *)service
{
    NSString *serviceString = [NSString stringWithFormat:@"-%@-%@--%@", self.component, self.logicalComponent, self.serviceID];
    return [[SAVService alloc] initWithString:serviceString];
}

- (NSString *)scope
{
    return [NSString stringWithFormat:@"%@.%@", self.component, self.logicalComponent];
}

- (void)applyValue:(id)value forSetting:(NSString *)setting immediately:(BOOL)immediately
{
    //-------------------------------------------------------------------
    // Add the settings to the settings or outstand settings.
    //-------------------------------------------------------------------
    NSMutableDictionary *settings = immediately ? self.settings : nil;

    if (value)
    {
        settings[setting] = value;

        //-------------------------------------------------------------------
        // Save the settings in combined settings (commited and not commited).
        //-------------------------------------------------------------------
        self.combinedSettings[setting] = value;
    }
    else
    {
        [settings removeObjectForKey:setting];
        [self.combinedSettings removeObjectForKey:setting];
    }
}

- (void)commit
{
    //-------------------------------------------------------------------
    // Save the outstanding settings into the settings dict.
    //-------------------------------------------------------------------
    self.settings = self.combinedSettings;
    self.combinedSettings = [[self.settings copy] mutableCopy];
}

- (void)rollback
{
    self.combinedSettings = [[self.settings copy] mutableCopy];
}

@end
