//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2013 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2013 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2013 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Duarte Avelar
//
// DESCRIPTION:
//
//====================================================================

@import Foundation;

extern NSString *const SCInvalidArgumentException;

typedef NS_ENUM(uint32_t, SCQueryVersion)
{
    SCQueryVersion_1 = 1,
    SCQueryVersion_2 = 2,
    SCQueryVersion_3 = 3,
    SCQueryVersion_4 = 4,
    SCQueryVersion_5 = 5,
    SCQueryVersion_6 = 6,
    SCQueryVersion_7 = 7,
    SCQueryVersion_8 = 8,
    SCQueryVersion_9 = 9,
    SCQueryVersion_10 = 10,
    SCQueryVersion_11 = 11,
    SCQueryVersion_12 = 12,
    SCQueryVersion_13 = 13
};

@interface SAVQuery : NSObject

@property (readonly) SCQueryVersion queryVersion;
@property NSSet *serviceBlacklist;
@property NSSet *zoneBlacklist;
@property NSSet *hiddenRooms;

- (instancetype)initWithVersion:(SCQueryVersion)version;
- (NSString *)version;
- (NSString *)allRooms;
- (NSString *)roomForRoomID;
- (NSString *)services;
- (NSString *)allServices;
- (NSString *)stateScopes;
- (NSString *)zonesInRoom;
- (NSString *)hvacEntities;
- (NSString *)poolAndSpaEntities;
- (NSString *)lightingEntities;
- (NSString *)shadeEntities;
- (NSString *)cameraEntities;
- (NSString *)securityEntities;
- (NSString *)allRoomIds;
- (NSString *)allHiddenRoomIds;
- (NSString *)roomGroups;
- (NSString *)roomsInGroup;
- (NSString *)ungroupedRooms;
- (NSString *)zonesWhichHaveService;
- (NSString *)servicesWhichHaveZones;
- (NSString *)requests;
- (NSString *)enabledRequests;

@end
