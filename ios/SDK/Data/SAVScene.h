//
//  SAVScene.h
//  SavantControl
//
//  Created by Nathan Trapp on 7/22/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import UIKit;
#import "SAVImageModel.h"

typedef NS_ENUM(NSInteger, SAVSceneScheduleDays)
{
    SAVSceneScheduleDay_Sunday    = 0,
    SAVSceneScheduleDay_Monday    = 1,
    SAVSceneScheduleDay_Tuesday   = 2,
    SAVSceneScheduleDay_Wednesday = 3,
    SAVSceneScheduleDay_Thursday  = 4,
    SAVSceneScheduleDay_Friday    = 5,
    SAVSceneScheduleDay_Saturday  = 6
};

@class SAVService, SAVServiceGroup;

@interface SAVSceneService : NSObject <NSCopying>

+ (SAVSceneService *)sceneServiceWithSettings:(NSDictionary *)settings serviceID:(NSString *)serviceID andScope:(NSString *)scope;

- (NSDictionary *)dictionaryRepresentation;
- (void)applySettings:(NSDictionary *)settings;

@property (readonly, nonatomic) SAVService *service;
@property (readonly, nonatomic) NSString *scope;

@property NSString *logicalComponent;
@property NSString *component;
@property NSString *serviceID;
@property (nonatomic) NSDictionary *mediaNode;

/**
 *  A dictionary of values keyed by state name.
 */
@property (readonly, atomic) NSDictionary *states;
/**
 *  A dictionary of values keyed by state name. Includes commited and non-commited states.
 */
@property (readonly, atomic) NSDictionary *combinedStates;
/**
 *  An array of rooms in use for a given service.
 */
@property NSMutableArray *rooms;
/**
 *  An array of zones in use for a given service.
 */
@property NSMutableArray *zones;

/**
 *  Apply a value for a setting. If you pass NO for the immediately flag, you will eventually either need to call @p -rollback, or @p -commit .
 *
 *  @param value       The value.
 *  @param setting     The setting.
 *  @param immediately YES to apply the setting immediately; otherwise, NO.
 */
- (void)applyValue:(id)value forSetting:(NSString *)setting immediately:(BOOL)immediately;

/**
 *  Apply all the outstanding settings.
 */
- (void)commit;

/**
 *  Discard all the outstanding settings.
 */
- (void)rollback;

@end

typedef NS_ENUM(NSInteger, SAVSceneDay)
{
    SAVSceneDay_Sunday    = 0,
    SAVSceneDay_Monday    = 1,
    SAVSceneDay_Tuesday   = 2,
    SAVSceneDay_Wednesday = 3,
    SAVSceneDay_Thursday  = 4,
    SAVSceneDay_Friday    = 5,
    SAVSceneDay_Saturday  = 6
};

typedef NS_ENUM(NSInteger, SAVSceneScheduleType)
{
    SAVSceneScheduleType_Normal,
    SAVSceneScheduleType_Countdown,
    SAVSceneScheduleType_Celestial
};

typedef NS_ENUM(NSInteger, SAVSceneCelestialType)
{
    SAVSceneCelestialType_Dawn,
    SAVSceneCelestialType_Dusk,
    SAVSceneCelestialType_Sunrise,
    SAVSceneCelestialType_Sunset
};

typedef void (^SAVSceneImageChangeCallback)(UIImage *image, UIImage *blurredImage);

@interface SAVScene : NSObject <NSCopying>

+ (SAVScene *)sceneWithSettings:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;
- (void)applySettings:(NSDictionary *)settings;

/**
 *  The scene name.
 */
@property NSString *name;

/**
 *  The scenes unique identifier.
 */
@property NSString *identifier;

/**
 *  Indicates if this scene is a global scene.
 */
@property (getter = isGlobal) BOOL global;

/**
 *  Indicates if this scene is currently active (only applies to scheduled scenes).
 */
@property (getter = isActive) BOOL active;

/**
 *  The image associated with the scene.
 */
@property UIImage *image;

/**
 *  The blurred image associated with the scene.
 */
@property UIImage *blurredImage;

/**
 *  A block that notifies whenever the scene image has changed.
 */
@property (nonatomic, copy) SAVSceneImageChangeCallback imageChangeCallback;

/**
 *  Indicates if the scenes image is a user provided image.
 */
@property BOOL hasCustomImage;

/**
 *  A key that indicates the scenes image.
 */
@property (nonatomic) NSString *imageKey;

/**
 *  A list of tags used for grouping/sorting the scene objects.
 */
@property (nonatomic) NSMutableArray *tags;

/**
 *  An array containing all the lighting SAVSceneService objects for a scene.
 */
@property (readonly, atomic) NSArray *lightingServices;

/**
 *  An array containing all the HVAC SAVSceneService objects for a scene.
 */
@property (readonly, atomic) NSArray *hvacServices;

/**
 *  An array containing all the AV SAVSceneService objects for a scene.
 */
@property (readonly, atomic) NSArray *avServices;

/**
 *  An array containing all the SAVSceneService objects for a scene.
 */
@property (readonly, atomic) NSArray *services;

/**
 *  Image size for scene images, defaults to medium.
 */
@property (nonatomic) SAVImageSize imageSize;

/**
 *  Add a lighting scene service.
 *
 *  @param service The scene service to add.
 */
- (void)addLightingSceneService:(SAVSceneService *)service;

/**
 *  Remove a lighting scene service.
 *
 *  @param service The scene service to remove.
 */
- (void)removeLightingSceneService:(SAVSceneService *)service;

/**
 *  Add a HVAC scene service.
 *
 *  @param service The scene service to add.
 */
- (void)addHVACSceneService:(SAVSceneService *)service;

/**
 *  Remove a HVAC scene service.
 *
 *  @param service The scene service to remove.
 */
- (void)removeHVACSceneService:(SAVSceneService *)service;

/**
 *  Add a AV scene service.
 *
 *  @param service The scene service to add.
 */
- (void)addAVSceneService:(SAVSceneService *)service;
/**
 *  Remove a AV scene service.
 *
 *  @param service The scene service to remove.
 */
- (void)removeAVSceneService:(SAVSceneService *)service;

/**
 *  Return the existing SAVSceneService for the given service. If one does not exist, it will be created and added.
 *
 *  @param service The service.
 *
 *  @return The existing or newly created SAVSceneService.
 */
- (SAVSceneService *)sceneServiceForService:(SAVService *)service;

/**
 *  Return the matching service group for a given scene service.
 *
 *  @param sceneService The scene service
 *
 *  @return SAVServiceGroup matching the scene service
 */
- (SAVServiceGroup *)serviceGroupForSceneService:(SAVSceneService *)sceneService;

/**
 *  All service groups, based on the avPower object.
 *
 *  @return An array of service groups.
 */
- (NSArray *)serviceGroups;

/**
 *  Indicates if this is a scheduled scene.
 */
@property (getter = isScheduled) BOOL scheduled;

/**
 *  The scheduled repeat period, "weekly", "yearly", or "daily".
 */
@property NSString *repeatPeriod;

/**
 *  The scheduled days. This is an array containing the SAVSceneSchedule days to enable.
 */
@property NSMutableArray *days;

/**
 *  The schedule time. This is the number of seconds since midnight.
 */
@property NSTimeInterval time;

/**
 *  Define that a scene should operate year round without a defined date range.
 */
@property (nonatomic, getter = isAllYear) BOOL allYear;

/**
 *  The given start and end date for the schedule.
 */
@property (nonatomic) NSDate *startDate, *endDate;

/**
 *  Define the type of schedule, defaults to normal.
 */
@property SAVSceneScheduleType scheduleType;

/**
 *  A string representation of the schedule type.
 */
@property (readonly, nonatomic) NSString *scheduleTypeString;

/**
 *  Define the celestial reference time. Only used if the schedule is of celestial type.
 */
@property SAVSceneCelestialType celestialReference;

/**
 *  A string representation of the celestial reference.
 */
@property (readonly, nonatomic) NSString *celestialTypeString;

/**
 *  String representations of the scheduled day and date range.
 */
@property (readonly, nonatomic) NSString *dayString, *dateString, *timeString;

/**
 *  Time over which the scene should fade in.
 */
@property NSTimeInterval fadeTime;

/**
 *  A dictionary mapping volume levels to rooms.
 */
@property NSMutableDictionary *volume;

/**
 *  A dictionary containing a service to power state for each room.
 *  When the room dictionary is empty, it should be treated as all off for that room.
 */
@property NSMutableDictionary *avPower;

/**
 *  An array represeting the lighting/hvac rooms to power off.
 */
@property NSMutableArray *lightingOff, *hvacOff;

/**
 *  An array representing the av off zones, as indicated in the avPower object.
 */
@property (readonly, atomic) NSArray *avOff;

/**
 *  Indicates if this scene is an all off scene.
 *  If this value is true, additional power settings should be ignored.
 */
@property (getter = isAllOff) BOOL allOff;

/**
 *  Bookkeeping. Set this to YES when the scene was capture. Not propagated anywhere.
 */
@property (nonatomic) BOOL wasCaptured;

@end
