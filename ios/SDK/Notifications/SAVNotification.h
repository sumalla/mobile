//
//  SAVNotification.h
//  SavantControl
//
//  Created by Cameron Pulsford on 1/14/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, SAVNotificationScheduleDays)
{
    SAVNotificationScheduleDay_Sunday    = 0,
    SAVNotificationScheduleDay_Monday    = 1,
    SAVNotificationScheduleDay_Tuesday   = 2,
    SAVNotificationScheduleDay_Wednesday = 3,
    SAVNotificationScheduleDay_Thursday  = 4,
    SAVNotificationScheduleDay_Friday    = 5,
    SAVNotificationScheduleDay_Saturday  = 6
};

typedef NS_ENUM(NSInteger, SAVNotificationDay)
{
    SAVNotificationDay_Sunday    = 0,
    SAVNotificationDay_Monday    = 1,
    SAVNotificationDay_Tuesday   = 2,
    SAVNotificationDay_Wednesday = 3,
    SAVNotificationDay_Thursday  = 4,
    SAVNotificationDay_Friday    = 5,
    SAVNotificationDay_Saturday  = 6
};

typedef NS_ENUM(NSInteger, SAVNotificationScheduleType)
{
    SAVNotificationScheduleType_Normal,
    SAVNotificationScheduleType_Celestial
};

typedef NS_ENUM(NSInteger, SAVNotificationCelestialType)
{
    SAVNotificationCelestialType_Dawn,
    SAVNotificationCelestialType_Dusk,
    SAVNotificationCelestialType_Sunrise,
    SAVNotificationCelestialType_Sunset
};

typedef NS_ENUM(NSInteger, SAVNotificationServiceType)
{
    SAVNotificationServiceTypeEntertainment = 0,
    SAVNotificationServiceTypeLighting = 1,
    SAVNotificationServiceTypeTemperature = 2,
    SAVNotificationServiceTypeHumidity = 3,
};

@interface SAVNotification : NSObject <NSCopying>

/**
 * A UID
 */
@property (nonatomic) NSString *identifier;
/**
 * Indicates if push notifications are enabled
 */
@property (getter = isPushDeliveryEnabled) BOOL pushDeliveryEnabled;
/**
 * Indicates if sms notifications are enabled
 */
@property (getter = isSmsDeliveryEnabled) BOOL smsDeliveryEnabled;
/**
 * Indicates if email notifications are enabled
 */
@property (getter = isEmailDeliveryEnabled) BOOL emailDeliveryEnabled;
/**
 * Indicates if the notification is enabled
 */
@property (getter = isEnabled) BOOL enabled;
/**
 *  A string representation of a service
 */
@property (nonatomic) NSString *service;
/**
 *  An array of rooms in use for a given service.
 */
@property (nonatomic) NSMutableArray *rooms;
/**
 *  An array of zones in use for a given service.
 */
@property (nonatomic) NSMutableArray *zones;
/**
 * The notification's service type
 */
@property SAVNotificationServiceType serviceType;

/**
 *  An array trigger values
 */
@property (nonatomic) NSMutableArray *triggerValues;
/**
 *  The trigger comparator
 */
@property (nonatomic) NSString *triggerComparison;

/**
 *  Indicates if this is a scheduled notification.
 */
@property (readonly, nonatomic, getter = isScheduled) BOOL scheduled;
/**
 *  Define that a notification should operate year round without a defined date range.
 */
@property (readonly, nonatomic, getter = isAllYear) BOOL allYear;
/**
 *  Define that a notification should operate all day without a defined time range.
 */
@property (readonly, nonatomic, getter = isAllDay) BOOL allDay;
/**
 *  The scheduled days. This is an array containing the SAVNotificationSchedule days to enable.
 */
@property (nonatomic) NSMutableArray *days;
/**
 *  The schedule times. This is the number of seconds since midnight.
 */
@property NSTimeInterval time, endTime;
/**
 *  The given start and end date for the schedule.
 */
@property (nonatomic) NSDate *startDate, *endDate;

/**
 *  Define the type of schedule, defaults to normal.
 */
@property SAVNotificationScheduleType scheduleType;

/**
 *  Define the celestial reference start time. Only used if the schedule is of celestial type.
 */
@property SAVNotificationCelestialType celestialReferenceStart;

/**
 *  Define the celestial reference end time. Only used if the schedule is of celestial type.
 */
@property SAVNotificationCelestialType celestialReferenceEnd;

/**
 *  Define the celestial reference start time offset. Only used if the schedule is of celestial type.
 */
@property NSTimeInterval startOffset;

/**
 *  Define the celestial reference end time offset. Only used if the schedule is of celestial type.
 */
@property NSTimeInterval endOffset;

/**
 *  A string representation of the celestial reference.
 */
@property (readonly, nonatomic) NSString *celestialTypeStringStart;

/**
 *  A string representation of the celestial reference.
 */
@property (readonly, nonatomic) NSString *celestialTypeStringEnd;

/**
 *  A string representation of the schedule type.
 */
@property (readonly, nonatomic) NSString *scheduleTypeString;

/**
 *  String representations of the scheduled day and date range.
 */
@property (readonly, nonatomic) NSString *dayString, *dateString, *timeString;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (void)applySettings:(NSDictionary *)settings;

- (NSDictionary *)dictionaryRepresentation;

- (NSDictionary *)ruleDictionaryRepresentation;

- (NSDictionary *)deliveryMethodsDictionaryRepresentation;

@end
