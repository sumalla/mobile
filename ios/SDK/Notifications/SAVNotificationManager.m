//
//  SAVNotificationManager.m
//  SavantControl
//
//  Created by Cameron Pulsford on 1/14/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

#import "SAVNotificationManager.h"
#import "SAVControlPrivate.h"
#import "SAVCloudServices.h"
#import "SavantPrivate.h"
@import Extensions;

static NSString *const SAVNotificationIdentifierKey   = @"id";

@interface SAVNotificationManager ()

@property (nonatomic) NSMutableArray *demoNotificationData;
@property (nonatomic) NSMutableArray *notificationCache;

@end

static NSString *const SAVNotificationPayload = @"payload";

@implementation SAVNotificationManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        dateFormatter.dateFormat = @"MM/dd";
        
        NSDate *startDate = [dateFormatter dateFromString:@"7/1"];
        
        SAVNotification *notification1 = [[SAVNotification alloc] init];
        notification1.pushDeliveryEnabled = YES;
        notification1.smsDeliveryEnabled = YES;
        notification1.emailDeliveryEnabled = YES;
        notification1.enabled = YES;
        notification1.identifier = @"demoID";
        notification1.service = nil;
        notification1.rooms = [@[] mutableCopy];
        notification1.zones = [@[] mutableCopy];
        notification1.serviceType = SAVNotificationServiceTypeTemperature;
        notification1.triggerValues = [@[@(32),@(96)] mutableCopy];
        notification1.days = nil;
        notification1.startDate = startDate;
        notification1.endDate = startDate;
        notification1.scheduleType = SAVNotificationScheduleType_Normal;
        notification1.celestialReferenceStart = SAVNotificationCelestialType_Dawn;
        notification1.celestialReferenceEnd = SAVNotificationCelestialType_Dawn;
        notification1.time = -1;
        notification1.endTime = -1;
        notification1.startOffset = 0;
        notification1.endOffset = 0;
        
        SAVNotification *notification2 = [[SAVNotification alloc] init];
        notification2.pushDeliveryEnabled = YES;
        notification2.smsDeliveryEnabled = YES;
        notification2.emailDeliveryEnabled = YES;
        notification2.enabled = NO;
        notification2.identifier = @"demoID";
        notification2.service = nil;
        notification2.rooms = [@[] mutableCopy];
        notification2.zones = [@[] mutableCopy];
        notification2.serviceType = SAVNotificationServiceTypeHumidity;
        notification2.triggerValues = [@[@(40),@(60)] mutableCopy];
        notification2.days = nil;
        notification2.startDate = startDate;
        notification2.endDate = startDate;
        notification2.scheduleType = SAVNotificationScheduleType_Normal;
        notification2.celestialReferenceStart = SAVNotificationCelestialType_Dawn;
        notification2.celestialReferenceEnd = SAVNotificationCelestialType_Dawn;
        notification2.time = -1;
        notification2.endTime = -1;
        notification2.startOffset = 0;
        notification2.endOffset = 0;
        
        self.demoNotificationData = [@[notification1, notification2] mutableCopy];
    }
    
    return self;
}

- (void)registerClientIfNecessary:(SAVNotificationClientRegistrationHandler)completionHandler
{
    BOOL wasNecessary = NO;
    [[Savant scs] registerClientNecessary:&wasNecessary completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        completionHandler(success, wasNecessary);
    }];
}

- (void)startWithToken:(NSData *)token
{
    if (![token length])
    {
        [NSException raise:NSInternalInconsistencyException format:@"Token data must be valid"];
        return;
    }
    
    [[Savant scs] updatePushNotificationToken:[token hexRepresentation]];
}

- (void)registerNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler
{
    if ([self isUnique:notification])
    {
        if ([Savant control].isDemoSystem)
        {
            [self.demoNotificationData addObject:notification];
            completionHandler(YES, nil);
        }
        else
        {
            NSString *homeID = [Savant control].currentSystem.homeID;
            [[Savant scs] registerNotificationTrigger:notification
                                                                    homeID:homeID
                                                         completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                                                             completionHandler(success, error);
                                                         }];
        }
    }
    else
    {
        completionHandler(YES, nil);
    }
}

- (void)unregisterNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler
{
    if ([Savant control].isDemoSystem)
    {
        [self.demoNotificationData removeObject:notification];
        completionHandler(YES, nil);
    }
    else
    {
        NSString *homeID = [Savant control].currentSystem.homeID;
        [[Savant scs] unregisterNotificationTrigger:notification
                                                                  homeID:homeID
                                                       completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                                                           completionHandler(success, error);
                                                       }];
    }
}

- (void)setNotification:(SAVNotification *)notification enabled:(BOOL)enabled completionHandler:(SAVNotificationResponse)completionHandler
{
    if ([Savant control].isDemoSystem)
    {
        for (SAVNotification *note in self.demoNotificationData)
        {
            if ([[notification dictionaryRepresentation] isEqualToDictionary:[note dictionaryRepresentation]])
            {
                note.enabled = enabled;
            }
        }
        
        completionHandler(YES, nil);
    }
    else
    {
        NSString *homeID = [Savant control].currentSystem.homeID;
        [[Savant scs] setNotification:notification
                                                   enabled:enabled
                                                    homeID:homeID
                                         completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                                             completionHandler(success, error);
                                         }];
    }
}

- (void)updateTriggerForNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler
{
    if ([Savant control].isDemoSystem)
    {
        for (SAVNotification *note in self.demoNotificationData)
        {
            if ([[notification dictionaryRepresentation] isEqualToDictionary:[note dictionaryRepresentation]])
            {
                
            }
        }
        
        completionHandler(YES, nil);
        completionHandler(YES, nil);
    }
    else
    {
        NSString *homeID = [Savant control].currentSystem.homeID;
        
        [[Savant scs] editNotificationTrigger:notification
                                                            homeID:homeID
                                                 completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                                                     completionHandler(success, error);
                                                 }];
    }
}

- (void)registeredNotificationsWithCompletionHandler:(SAVNotificationPayloadResponse)completionHandler
{
    if (!completionHandler)
    {
        [NSException raise:NSInternalInconsistencyException format:@"There must be a completion handler %s", __PRETTY_FUNCTION__];
        return;
    }
    
    if ([Savant control].isDemoSystem)
    {
        dispatch_async_main(^{
            self.notificationCache = [self.demoNotificationData mutableCopy];
            
            completionHandler(YES, nil, [self.demoNotificationData copy]);
        });
    }
    else
    {
        __block NSString *homeID = [Savant control].currentSystem.homeID;
        [[Savant scs] listNotificationTriggersWithHomeID:homeID completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
            
            NSArray *payload = [[NSArray alloc] init];
            
            if (success && data)
            {
                for (NSDictionary *dict in data)
                {
                    payload = [payload arrayByAddingObject:[[SAVNotification alloc] initWithDictionary:dict]];
                }
                
                self.notificationCache = [payload mutableCopy];
            }
            
            completionHandler(success, error, payload);
        }];
    }
}

- (BOOL)isUnique:(SAVNotification *)notification
{
    BOOL isUnique = YES;

    NSMutableDictionary *note = [[notification dictionaryRepresentation] mutableCopy];
    [note removeObjectForKey:SAVNotificationIdentifierKey];
    
    for (SAVNotification *existingNotification in self.notificationCache)
    {
        NSMutableDictionary *existingNote = [[existingNotification dictionaryRepresentation] mutableCopy];
        [existingNote removeObjectForKey:SAVNotificationIdentifierKey];
        
        NSLog(@"EXISTING: %@", existingNote);
        NSLog(@"NEW: %@", note);
        
        if ([note isEqualToDictionary:existingNote])
        {
            isUnique = NO;
        }
    }

    return isUnique;
}

- (NSMutableArray *)demoNotificationData
{
    if (!_demoNotificationData)
    {
        _demoNotificationData = [[NSMutableArray alloc] init];
    }
    
    return _demoNotificationData;
}
    
- (NSMutableArray *)notificationCache
{
    if (!_notificationCache)
    {
        _notificationCache = [[NSMutableArray alloc] init];
    }
    
    return _notificationCache;
}

@end

