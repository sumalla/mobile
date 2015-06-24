//
//  SAVClimateSchedule.h
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SAVClimateScheduleScale)
{
    SAVClimateScheduleScale_Farenheit,
    SAVClimateScheduleScale_Celcius
};

typedef NS_ENUM(NSInteger, SAVClimateScheduleMode)
{
    SAVClimateScheduleMode_Auto,
    SAVClimateScheduleMode_Heat,
    SAVClimateScheduleMode_Cool,
    SAVClimateScheduleMode_Unknown = -1
};

typedef NS_ENUM(NSInteger, SAVClimateSetPointType)
{
    SAVClimateSetPointType_HumidifyDehumidify,
    SAVClimateSetPointType_Humidity,
    SAVClimateSetPointType_Temperature
};

typedef NS_ENUM(NSInteger, SAVClimateScheduleDay)
{
    SAVClimateScheduleDay_Sunday    = 0,
    SAVClimateScheduleDay_Monday    = 1,
    SAVClimateScheduleDay_Tuesday   = 2,
    SAVClimateScheduleDay_Wednesday = 3,
    SAVClimateScheduleDay_Thursday  = 4,
    SAVClimateScheduleDay_Friday    = 5,
    SAVClimateScheduleDay_Saturday  = 6
};

extern NSString *const SAVClimateScheduleNameKey;
extern NSString *const SAVClimateScheduleNameOldKey;
extern NSString *const SAVClimateScheduleActiveKey;
extern NSString *const SAVClimateScheduleDateRangeKey;
extern NSString *const SAVClimateScheduleDaysKey;
extern NSString *const SAVClimateScheduleZonesKey;
extern NSString *const SAVClimateSchedulePropertiesKey;
extern NSString *const SAVClimateScheduleProfilePointsKey;
extern NSString *const SAVClimateScheduleHumidityPointsKey;
extern NSString *const SAVClimateScheduleTempPointsKey;
extern NSString *const SAVClimateScheduleHVACModeKey;

//-------------------------------------------------------------------
// Settings Keys
//-------------------------------------------------------------------
extern NSString *const SAVClimateScheduleHumidityMaxKey;
extern NSString *const SAVClimateScheduleHumidityMinKey;
extern NSString *const SAVClimateScheduleHumidifyKey;
extern NSString *const SAVClimateScheduleDeHumidifyKey;
extern NSString *const SAVClimateScheduleTempMaxKey;
extern NSString *const SAVClimateScheduleTempMinKey;
extern NSString *const SAVClimateScheduleTempScale;
extern NSString *const SAVClimateScheduleHumidityBufferKey;
extern NSString *const SAVClimateScheduleTempBufferKey;

@interface SAVClimateSchedule : NSObject <NSCopying>

+ (SAVClimateSchedule *)demoScheduleWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)scheduleName;
- (NSDictionary *)dictionaryRepresentation;
- (void)applySettings:(NSDictionary *)settings;
- (void)applyGlobalSettings:(NSDictionary *)settings;
- (NSString *)dayString;
- (NSString *)dateString;
- (NSString *)shortDateString;

+ (NSString *)stringForHVACMode:(SAVClimateScheduleMode)mode;
+ (SAVClimateScheduleMode)hvacModeFromString:(NSString *)mode;

+ (NSString *)stringForDay:(SAVClimateScheduleDay)day;
+ (NSString *)shortStringForDay:(SAVClimateScheduleDay)day;

/**
 *  The schedule name.
 */
@property NSString *name;
/**
 *  The previous schedule name if it was changed, so the backend doesn't lose its mapping.
 */
@property NSString *oldName;
/**
 *  Is this a yearly schedule.
 */
@property (readonly, atomic) BOOL isAllYear;
/**
 *  If the schedule is not yearly, the range of dates that is covered.
 */
@property NSDictionary *dateRange;
/**
 *  The days of the week the schedule is active.
 */
@property NSArray *days;
/**
 *  The zones in which the schedule is active.
 */
@property NSArray *zones;
/**
 *  Is this schedule currently active.
 */
@property (getter = isActive) BOOL active;
/**
 *  A list of set points, including time.
 */
@property NSArray *humiditySetPoints, *temperatureSetPoints;
/**
 *  The HVAC mode that applies to the temperature set points.
 */
@property SAVClimateScheduleMode hvacMode;
/**
 *  The format that applies to the humidiy set points.
 */
@property SAVClimateSetPointType humidityType;
/**
 *  The temperature scale (Farenheit, Celsius)
 */
@property SAVClimateScheduleScale scale;
/**
 *  The buffer required between set points.
 */
@property NSInteger humidityPointBuffer, temperaturePointBuffer;
/**
 *  The maximum and minimum allowed humidity point.
 */
@property CGFloat humidityMaxPoint, humidityMinPoint;
/**
 *  The maximum and minimum allowed temperature point.
 */
@property CGFloat temperatureMaxPoint, temperatureMinPoint;

@property (readonly, atomic) CGFloat temperatureRange, humidityRange;

@end

@interface SAVClimateSetPoint : NSObject <NSCopying>

@property (nonatomic) CGFloat range;
@property (nonatomic) NSString *time;
@property (nonatomic) CGFloat point1, point2;
@property (nonatomic) CGFloat rawPoint1, rawPoint2;
@property (nonatomic) CGFloat minPoint;
@property (nonatomic) CGFloat buffer;
@property (nonatomic) SAVClimateSetPointType type;

- (instancetype)initWithSettings:(NSDictionary *)settings minPoint:(CGFloat)minPoint buffer:(CGFloat)buffer andRange:(CGFloat)range andType:(SAVClimateSetPointType)type;
- (instancetype)initWithRange:(CGFloat)range minPoint:(CGFloat)minPoint buffer:(CGFloat)buffer point1:(CGFloat)p1 point2:(CGFloat)p2 time:(NSString *)time andType:(SAVClimateSetPointType)type;
- (NSDictionary *)dictionaryRepresentation;

@end
