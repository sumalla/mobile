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
// AUTHOR: Duarte Avelar/Ian Mortimer
//
// DESCRIPTION:
//
//====================================================================

#import "SAVData.h"
#import "SAVDataPrivate.h"
#import <sqlite3.h>
#import "SAVServiceRequest.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "SAVControlPrivate.h"
#import "SAVRoomGroup.h"
#import "SAVMutableService.h"
#import "SAVHVACEntity.h"
#import "SAVPoolEntity.h"
#import "SAVLightEntity.h"
#import "SAVShadeEntity.h"
#import "SAVCameraEntity.h"
#import "SAVSecurityEntity.h"
#import "SAVZone.h"
#import "SAVSettings.h"
#import "SAVQuery.h"
#import "Savant.h"
@import Extensions;

NSString *const kSystemSQLDataFile = @"serviceImplementation.sqlite";
static NSString *const kSAVGlobalEnvZone  = @"SAVANT_GLOBAL_ENV_ZONE";

NSString *const SAVFavoritesIconNameKey  = @"SAVFavoritesIconNameKey";
NSString *const SAVFavoritesIconImageKey = @"SAVFavoritesIconImageKey";

static NSString *const SAVFavoritesListKey = @"favorites";
NSString *const SAVFavoriteNumberKey = @"channelNum";
NSString *const SAVFavoriteImageKey = @"imageRef";
NSString *const SAVFavoriteDescriptionKey = @"channelDescription";

NSString *const SAVShownObjectsArrayKey  = @"shownObjects";
NSString *const SAVHiddenObjectsArrayKey = @"hiddenObjects";
static NSString *const SAVDynamicOrderingDictKey = @"dynamicObjects";

@interface SAVData ()

@property SAVQuery *queryManager;
@property (nonatomic) NSString *databasePath;
@property NSSet *serviceBlacklist;
@property NSSet *zoneBlacklist;
//@property FMDatabaseQueue *databaseQueue;

@end

@implementation SAVData

#define wildcardForNil(v) [v length] ? v : @"%"

- (FMDatabaseQueue *)createDatabaseQueue
{
    if (self.databasePath)
    {
        return [FMDatabaseQueue databaseQueueWithPath:self.databasePath flags:SQLITE_OPEN_READONLY];
    }
    else
    {
        return nil;
    }
}

- (void)setServiceToResourceMap:(NSData *)json
{
    self.resourceMap = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
}

- (void)updateDatabasePath:(NSString *)databasePath
{
    self.databasePath = databasePath;
    
    if (databasePath)
    {
        self.queryManager = [[SAVQuery alloc] initWithVersion:(SCQueryVersion)[self version]];
        [self updateServiceBlacklist:[NSSet set] zoneBlacklist:[NSSet set]];
    }
    else
    {
        self.queryManager = nil;
    }
}

- (void)updateServiceBlacklist:(NSSet *)serviceBlacklist zoneBlacklist:(NSSet *)zoneBlacklist
{
    self.serviceBlacklist = serviceBlacklist;
    self.zoneBlacklist = zoneBlacklist;
    self.queryManager.serviceBlacklist = serviceBlacklist;
    self.queryManager.zoneBlacklist = zoneBlacklist;
    self.queryManager.hiddenRooms = [NSSet setWithArray:[self allHiddenRoomIds]];
}

#pragma mark - data methods

- (NSArray *)requestsFilteredByService:(SAVService *)service
{
    return [self requests:service onlyVisible:NO];
}

- (NSArray *)sortedRoomsWithRooms:(NSArray *)rooms
{
    NSArray *allRooms = [self allRoomIds];

    return [rooms sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [allRooms indexOfObject:obj1] < [allRooms indexOfObject:obj2] ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray *)allRoomIds
{
    NSMutableArray *roomIds = [[NSMutableArray alloc] init];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.allRoomIds];

        while ([results next])
        {
            [roomIds addObject:[results stringForColumn:@"name"]];
        }
    }];

    return [roomIds copy];
}

- (NSArray *)allHiddenRoomIds
{
    NSMutableArray *roomIds = [[NSMutableArray alloc] init];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.allHiddenRoomIds];

        while ([results next])
        {
            [roomIds addObject:[results stringForColumn:@"name"]];
        }
    }];

    return [roomIds copy];
}

- (NSArray *)allRoomGroups
{
    NSMutableArray *roomGroups = [[NSMutableArray alloc] init];

    //-------------------------------------------------------------------
    // Can't use [self createDatabaseQueue] here because we call other database
    // methods within the block.
    //-------------------------------------------------------------------
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:[self.queryManager roomGroups]];

        while ([results next])
        {
            NSString *groupId = [results stringForColumn:@"name"];

            if ([groupId length])
            {
                SAVRoomGroup *roomGroup = [[SAVRoomGroup alloc] init];
                roomGroup.groupId = groupId;

                //-------------------------------------------------------------------
                // Don't include empty room groups.
                //-------------------------------------------------------------------
                if ([[self roomsInRoomGroup:roomGroup] count]) /* This roomsInGroup call is why we can't use [self createDatabaseQueue] up above. */
                {
                    [roomGroups addObject:roomGroup];
                }
            }
        }
    }];

    return [roomGroups copy];
}

- (NSArray *)roomsInRoomGroup:(SAVRoomGroup *)roomGroup
{
    NSMutableArray *roomsInGroup = [[NSMutableArray alloc] init];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = nil;
        if (roomGroup.groupId)
        {
            results = [db executeQuery:[self.queryManager roomsInGroup] withArgumentsInArray:[NSArray arrayWithObject:roomGroup.groupId]];
        }
        else
        {
            results = [db executeQuery:[self.queryManager ungroupedRooms]];
        }

        while ([results next])
        {
            if (self.queryManager.queryVersion < SCQueryVersion_7 || [results boolForColumn:@"shown"])
            {
                SAVRoom *room = [[SAVRoom alloc] init];

                room.roomId = [results stringForColumn:@"name"];
                room.hasLighting = [results boolForColumn:@"hasLights"];
                room.hasShades = [results boolForColumn:@"hasShades"];
                room.hasHVAC = [results boolForColumn:@"hasHVAC"];
                room.hasAV = [results boolForColumn:@"hasAV"];
                room.hasSecurity = [results boolForColumn:@"hasSecurity"];
                room.hasCameras = [results boolForColumn:@"hasCameras"];
                
                if (self.queryManager.queryVersion >= SCQueryVersion_13)
                {
                    room.hasFans = [results boolForColumn:@"hasFans"];
                }

                [roomsInGroup addObject:room];

                SAVRoomGroup *tRoomGroup = [[SAVRoomGroup alloc] init];
                tRoomGroup.groupId = [results stringForColumn:@"groupName"];

                room.group = tRoomGroup;
            }
        }
    }];

    return [roomsInGroup copy];
}

- (NSArray *)serviceGroupsForServices:(NSArray *)services
{
    NSMutableDictionary *serviceGroups = [NSMutableDictionary dictionary];

    for (SAVService *service in services)
    {
        SAVServiceGroup *serviceGroup = serviceGroups[service.identifier];

        if (!serviceGroup)
        {
            serviceGroup = [[SAVServiceGroup alloc] init];
            serviceGroup.identifier = service.identifier;
            serviceGroups[service.identifier] = serviceGroup;
        }

        [serviceGroup addService:service];
    }

    return [serviceGroups allValues];
}

- (NSArray *)allServiceGroups
{
    NSArray *allServices = [self servicesFilteredByService:nil];

    return [self serviceGroupsForServices:allServices];
}

- (NSArray *)allServices
{
    NSMutableArray *allServices = [[NSMutableArray alloc] init];

    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager allServices]];

        while ([results next])
        {
            if ([results boolForColumn:@"show"] || self.queryManager.queryVersion < SCQueryVersion_2)
            {
                //                SAVService *serviceWithZone = [[SAVService alloc] init];

                NSString *component = [results stringForColumn:@"component"];
                NSString *logicalComponent = [results stringForColumn:@"logicalComponent"];
                NSString *serviceId = [results stringForColumn:@"serviceType"];
                NSString *alias = [results stringForColumn:@"alias"];
                NSString *connectorId = [results stringForColumn:@"connectorID"];
                SAVServiceAVIOType avioType = [SAVService avioTypeForString:[results stringForColumn:@"avioType"]];
                SAVServiceOutputType outputType = [SAVService outputTypeForString:[results stringForColumn:@"avType"]];

                BOOL discreteVolume = NO;

                if (self.queryManager.queryVersion >= SCQueryVersion_4)
                {
                    discreteVolume = [results boolForColumn:@"discreteVolume"];
                }

                NSString *serviceAlias = nil;

                if (self.queryManager.queryVersion >= SCQueryVersion_10)
                {
                    serviceAlias = [results stringForColumn:@"serviceNameAlias"] ? [results stringForColumn:@"serviceNameAlias"] : alias;
                }
                else
                {
                    serviceAlias = [results stringForColumn:@"alias"];
                }

                NSString *capabilitiesString = [results stringForColumn:@"capabilities"];
                NSArray *capabilities = nil;

                if (capabilitiesString != nil)
                {
                    capabilities = [capabilitiesString componentsSeparatedByString:@","];
                }

                [allServices addObject:[[SAVService alloc] initWithZone:nil
                                                              component:component
                                                       logicalComponent:logicalComponent
                                                              variantId:nil
                                                              serviceId:serviceId
                                                                  alias:alias
                                                           serviceAlias:serviceAlias
                                                            connectorId:connectorId
                                                           capabilities:capabilities
                                                               avioType:avioType
                                                             outputType:outputType
                                                         discreteVolume:discreteVolume
                                                                 hidden:NO]];
            }
        }
    }];

    return [allServices copy];
}

- (NSArray *)zonesWithService:(SAVService *)service
{
    //-------------------------------------------------------------------
    // CBP TODO: Check the service here.
    //-------------------------------------------------------------------
    NSMutableArray *zonesWithService = [[NSMutableArray alloc] init];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.serviceId), wildcardForNil(service.variantId), wildcardForNil(service.connectorId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager zonesWhichHaveService] withArgumentsInArray:arguments];

        while ([results next])
        {
            if ([results boolForColumn:@"show"] || self.queryManager.queryVersion < SCQueryVersion_2)
            {
                [zonesWithService addObject:[results stringForColumn:@"name"]];
            }
        }
    }];

    return [[self sortedRoomsWithRooms:zonesWithService] copy];
}

- (NSArray *)servicesWithZones:(SAVRoom *)room service:(SAVService *)service
{
    NSMutableArray *servicesWithZones = [[NSMutableArray alloc] init];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(room.roomId), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.serviceId), wildcardForNil(service.variantId), wildcardForNil(service.connectorId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager servicesWhichHaveZones] withArgumentsInArray:arguments];

        while ([results next])
        {
            if ([results boolForColumn:@"show"] || self.queryManager.queryVersion < SCQueryVersion_2)
            {
                NSString *zoneName = [results stringForColumn:@"zone"];
                NSString *component = [results stringForColumn:@"component"];
                NSString *logicalComponent = [results stringForColumn:@"logicalComponent"];
                NSString *variantId = [results stringForColumn:@"serviceVariantID"];
                NSString *serviceId = [results stringForColumn:@"serviceType"];
                NSString *alias = [results stringForColumn:@"alias"];
                NSString *connectorId = [results stringForColumn:@"connectorID"];
                SAVServiceAVIOType avioType = [SAVService avioTypeForString:[results stringForColumn:@"avioType"]];
                SAVServiceOutputType outputType = [SAVService outputTypeForString:[results stringForColumn:@"avType"]];

                BOOL discreteVolume = NO;

                if (self.queryManager.queryVersion >= SCQueryVersion_4)
                {
                    discreteVolume = [results boolForColumn:@"discreteVolume"];
                }

                NSString *serviceAlias = nil;

                if (self.queryManager.queryVersion >= SCQueryVersion_10)
                {
                    serviceAlias = [results stringForColumn:@"serviceNameAlias"] ? [results stringForColumn:@"serviceNameAlias"] : alias;
                }
                else
                {
                    serviceAlias = [results stringForColumn:@"alias"];
                }

                NSString *capabilitiesString = [results stringForColumn:@"capabilities"];
                NSArray *capabilities = nil;

                if (capabilitiesString != nil)
                {
                    capabilities = [capabilitiesString componentsSeparatedByString:@","];
                }

                [servicesWithZones addObject:[[SAVService alloc] initWithZone:zoneName
                                                                    component:component
                                                             logicalComponent:logicalComponent
                                                                    variantId:variantId
                                                                    serviceId:serviceId
                                                                        alias:alias
                                                                 serviceAlias:serviceAlias
                                                                  connectorId:connectorId
                                                                 capabilities:capabilities
                                                                     avioType:avioType
                                                                   outputType:outputType
                                                               discreteVolume:discreteVolume
                                                                       hidden:NO]];
            }
        }
    }];

    return [servicesWithZones copy];
}

- (NSArray *)HVACEntitiesForRoom:(NSString *)zone
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_HVAC"] || [self.zoneBlacklist containsObject:zone])
    {
        return @[];
    }

    NSParameterAssert(zone);
    SAVMutableService *filterService = [[SAVMutableService alloc] init];
    filterService.zoneName = zone;
    filterService.serviceId = @"SVC_ENV_HVAC";

    NSMutableArray *entities = [NSMutableArray array];

    for (SAVService *service in [self servicesFilteredByService:filterService])
    {
        [entities addObjectsFromArray:[self HVACEntities:zone zone:nil service:service]];
    }

    return [entities copy];
}

- (NSArray *)HVACEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_HVAC"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableArray *hvacEntities = [[NSMutableArray alloc] init];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:self.queryManager.hvacEntities withArgumentsInArray:arguments];

        while ([results next])
        {
            SAVMutableService *entityService = [[SAVMutableService alloc] init];
            entityService.component = [results stringForColumn:@"component"];
            entityService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            entityService.serviceId = [results stringForColumn:@"serviceID"];
            entityService.zoneName = [results stringForColumn:@"roomName"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                entityService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                entityService.capabilities = nil;
            }

            NSString *zoneName = [results stringForColumn:@"zoneName"];

            SAVHVACEntity *hvacEntity = [[SAVHVACEntity alloc] initWithRoomName:roomName zoneName:zoneName service:entityService];

            // Get the name
            hvacEntity.label = [results stringForColumn:@"name"];

            // Get the address. Split by ','.
            NSString *addressString = [results stringForColumn:@"addresses"];

            if (!addressString)
            {
                addressString = @"";
            }

            while ([addressString hasSuffix:@","])
            {
                addressString = [addressString substringWithRange:NSMakeRange(0, [addressString length] - 1)];
            }

            hvacEntity.addresses = [addressString componentsSeparatedByString:@","];

            // Get the set point counts.
            hvacEntity.heatSetPoint = [results boolForColumn:@"heat"];
            hvacEntity.coolSetPoint =  [results boolForColumn:@"cool"];
            hvacEntity.humidifySetPoint = [results boolForColumn:@"humidify"];
            hvacEntity.dehumidifySetPoint = [results boolForColumn:@"dehumidify"];

            hvacEntity.tempSPCount = [results intForColumn:@"temperatureSetPoints"];
            hvacEntity.humiditySPCount = [results intForColumn:@"humiditySetPoints"];

            if (self.queryManager.queryVersion >= SCQueryVersion_11)
            {
                hvacEntity.history = [results boolForColumn:@"history"];
            }
            else
            {
                hvacEntity.history = YES;
            }

            if (self.queryManager.queryVersion >= SCQueryVersion_12)
            {
                hvacEntity.autoMode = [results boolForColumn:@"auto"];
            }
            else
            {
                hvacEntity.autoMode = ((hvacEntity.heatSetPoint && hvacEntity.coolSetPoint) && hvacEntity.tempSPCount > 1);
            }

            [hvacEntities addObject:hvacEntity];
        }
    }];

    return [hvacEntities copy];
}

- (NSArray *)poolEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_POOLANDSPA"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableDictionary *poolEntities = [[NSMutableDictionary alloc]initWithCapacity:1];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(@"%"), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:self.queryManager.poolAndSpaEntities withArgumentsInArray:arguments];
        while ([results next])
        {
            SAVMutableService *entityService = [[SAVMutableService alloc] init];
            entityService.component = [results stringForColumn:@"component"];
            entityService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            entityService.serviceId = [results stringForColumn:@"serviceID"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                entityService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                entityService.capabilities = nil;
            }

            SAVPoolEntity *poolEntity = poolEntities[entityService.description];
            if (!poolEntity)
            {
                poolEntity = [[SAVPoolEntity alloc] initWithRoomName:roomName zoneName:zone service:entityService];
                poolEntity.type = SAVEntityType_Pool;
                poolEntity.label = entityService.component;
                [poolEntities setObject:poolEntity forKey:entityService.description];
            }

            // Get the name
            NSString *auxiliaryNumber = [results stringForColumn:@"auxiliaryNumber"];
            NSString *auxiliaryLabel = [results stringForColumn:@"name"];

            [poolEntity addAuxiliaryNumber:auxiliaryNumber label:auxiliaryLabel];
        }
    }];

    if (!service)
    {
        service = [[SAVService alloc] initWithZone:zone
                                         component:nil
                                  logicalComponent:nil
                                         variantId:nil
                                         serviceId:@"SVC_ENV_POOLANDSPA"];
    }

    NSMutableArray *poolServices = [[self servicesFilteredByService:service] mutableCopy];

    [poolServices filterArrayUsingBlock:^BOOL(SAVService *pService) {
        for (SAVEntity *pEntity in [poolEntities allValues])
        {
            if ([pService matchesWildcardedService:pEntity.service])
            {
                return NO;
            }
        }
        return YES;
    }];

    for (SAVService *poolService in poolServices)
    {
        NSObject *object = poolEntities[poolService.serviceString];
        if (!object)
        {
            poolEntities[poolService.serviceString] = [[SAVPoolEntity alloc] initWithRoomName:nil zoneName:nil service:poolService];
        }
    }

    if ([poolEntities count] < 1)
    {
        SAVPoolEntity *poolEntity = [[SAVPoolEntity alloc] initWithRoomName:roomName zoneName:zone service:service];
        return @[poolEntity];
    }

    return [poolEntities allValues];
}

- (NSArray *)lightEntitiesForRoom:(NSString *)room
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_LIGHTING"] || [self.zoneBlacklist containsObject:room])
    {
        return @[];
    }

    SAVMutableService *service = [[SAVMutableService alloc] init];
    service.zoneName = room;
    service.serviceId = @"SVC_ENV_LIGHTING";
    return [self lightEntities:room zone:nil service:service];
}

- (NSArray *)lightEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_LIGHTING"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableArray *lightEntities = [NSMutableArray array];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.lightingEntities withArgumentsInArray:arguments];

        while ([results next])
        {
            SAVMutableService *entityService = [[SAVMutableService alloc] init];
            entityService.component = [results stringForColumn:@"component"];
            entityService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            entityService.serviceId = [results stringForColumn:@"serviceID"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                entityService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                entityService.capabilities = nil;
            }

            SAVLightEntity *lightEntity =  [[SAVLightEntity alloc] initWithRoomName:roomName zoneName:zone service:entityService];

            // Get the name
            lightEntity.label = [self getLocalizedString:[results stringForColumn:@"name"]];

            // Get the address. Split by ','.
            NSString *addressString = [results stringForColumn:@"addresses"];

            if (!addressString)
            {
                addressString = @"";
            }

            while ([addressString hasSuffix:@","])
            {
                addressString = [addressString substringWithRange:NSMakeRange(0, [addressString length] - 1)];
            }

            lightEntity.addresses = [addressString componentsSeparatedByString:@","];

            // get the type of entity
            lightEntity.type = [lightEntity typeFromString:[results stringForColumn:@"entityType"]];
            // get press command
            lightEntity.pressCommand = [results stringForColumn:@"pressCommand"];
            // get hold command
            lightEntity.holdCommand = [results stringForColumn:@"holdCommand"];
            // get release command
            lightEntity.releaseCommand = [results stringForColumn:@"releaseCommand"];
            // get toggle Press command
            lightEntity.togglePressCommand = [results stringForColumn:@"togglePressCommand"];
            // get toggle hold command
            lightEntity.toggleHoldCommand = [results stringForColumn:@"toggleHoldCommand"];
            // get toggle release command
            lightEntity.toggleReleaseCommand = [results stringForColumn:@"toggleReleaseCommand"];
            // get dimmer command
            lightEntity.dimmerCommand = [results stringForColumn:@"dimmerCommand"];
            // get fade Time
            lightEntity.fadeTime = [results stringForColumn:@"fadeTime"];
            // get delay time
            lightEntity.delayTime = [results stringForColumn:@"delayTime"];
            // get state name
            lightEntity.stateName = [results stringForColumn:@"stateName"];
            // get entity identifier for faster mapping
            lightEntity.identifier = [results intForColumn:@"id"];

            // get isSceneable flag
            if (self.queryManager.queryVersion >= SCQueryVersion_5)
            {
                lightEntity.scenable = [[results objectForColumnName:@"isSceneable"] boolValue];
            }
            else
            {
                lightEntity.scenable = YES;
            }

            [lightEntities addObject:lightEntity];
        }
    }];

    return [lightEntities copy];
}

- (NSArray *)shadeEntitiesForRoom:(NSString *)zone
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_SHADE"] || [self.zoneBlacklist containsObject:zone])
    {
        return @[];
    }

    NSParameterAssert(zone);
    SAVMutableService *filterService = [[SAVMutableService alloc] init];
    filterService.zoneName = zone;
    filterService.serviceId = @"SVC_ENV_SHADE";

    NSMutableArray *entities = [NSMutableArray array];

    for (SAVService *service in [self servicesFilteredByService:filterService])
    {
        [entities addObjectsFromArray:[self shadeEntities:zone zone:nil service:service]];
    }

    return entities;
}

- (NSArray *)shadeEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_LIGHTING"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableArray *shadeEntities = [NSMutableArray array];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.shadeEntities withArgumentsInArray:arguments];

        while ([results next])
        {
            SAVMutableService *entityService = [[SAVMutableService alloc] init];
            entityService.component = [results stringForColumn:@"component"];
            entityService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            entityService.serviceId = [results stringForColumn:@"serviceID"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                entityService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                entityService.capabilities = nil;
            }

            SAVShadeEntity *shadeEntity = [[SAVShadeEntity alloc] initWithRoomName:roomName zoneName:zone service:entityService];

            // Get the name
            shadeEntity.label = [self getLocalizedString:[results stringForColumn:@"name"]];

            // Get the address. Split by ','.
            NSString *addressString = [results stringForColumn:@"addresses"];

            if (!addressString)
            {
                addressString = @"";
            }

            while ([addressString hasSuffix:@","])
            {
                addressString = [addressString substringWithRange:NSMakeRange(0, [addressString length] - 1)];
            }

            shadeEntity.addresses = [addressString componentsSeparatedByString:@","];

            // get the type of entity
            shadeEntity.type = [shadeEntity typeFromString:[results stringForColumn:@"entityType"]];
            // get press command
            shadeEntity.pressCommand = [results stringForColumn:@"pressCommand"];
            // get hold command
            shadeEntity.holdCommand = [results stringForColumn:@"holdCommand"];
            // get release command
            shadeEntity.releaseCommand = [results stringForColumn:@"releaseCommand"];
            // get toggle Press command
            shadeEntity.togglePressCommand = [results stringForColumn:@"togglePressCommand"];
            // get toggle hold command
            shadeEntity.toggleHoldCommand = [results stringForColumn:@"toggleHoldCommand"];
            // get toggle release command
            shadeEntity.toggleReleaseCommand = [results stringForColumn:@"toggleReleaseCommand"];
            // get fade Time
            shadeEntity.fadeTime = [results stringForColumn:@"fadeTime"];
            // get delay time
            shadeEntity.delayTime = [results stringForColumn:@"delayTime"];
            // get the identifier
            shadeEntity.identifier = [results intForColumn:@"id"];
            // get the state name
            shadeEntity.stateName = [results stringForColumn:@"stateName"];

            // get isSceneable flag
            if (self.queryManager.queryVersion >= SCQueryVersion_5)
            {
                shadeEntity.scenable = [[results objectForColumnName:@"isSceneable"] boolValue];
            }
            else
            {
                shadeEntity.scenable = YES;
            }

            [shadeEntities addObject:shadeEntity];
        }
    }];

    return [shadeEntities copy];
}

- (NSArray *)cameraEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_SECURITY"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableArray *cameraEntities = [NSMutableArray array];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.cameraEntities withArgumentsInArray:arguments];

        while ([results next])
        {
            //--------------------------------------------------
            // Get the room, zone and the service from the
            // database since cameras may be queried globally.
            //--------------------------------------------------
            NSString *entityRoom = [results stringForColumn:@"cameraRoom"];
            if ([entityRoom isEqualToString:kSAVGlobalEnvZone])
            {
                entityRoom = roomName;
            }

            NSString *cameraZone = [results stringForColumn:@"cameraZone"];
            BOOL inGlobalZone = NO;
            if ([cameraZone isEqualToString:kSAVGlobalEnvZone])
            {
                cameraZone = @"Global";
                inGlobalZone = YES;
            }

            // Create the service
            SAVMutableService *cameraService = [[SAVMutableService alloc] init];
            cameraService.zoneName = [results stringForColumn:@"zone"];
            cameraService.component = [results stringForColumn:@"component"];
            cameraService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            cameraService.variantId = [results stringForColumn:@"serviceVariantID"];
            cameraService.serviceId = [results stringForColumn:@"serviceType"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                cameraService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                cameraService.capabilities = nil;
            }

            // Create the entity
            SAVCameraEntity *cameraEntity =  [[SAVCameraEntity alloc] initWithRoomName:entityRoom zoneName:cameraZone service:cameraService];
            cameraEntity.inGlobalZone = inGlobalZone;

            // Get the name
            cameraEntity.label = [results stringForColumn:@"cameraName"];

            // Get the type of the entity
            cameraEntity.type = [cameraEntity typeFromString:[results stringForColumn:@"entityType"]];

            // Get the preview URL
            cameraEntity.previewURL = [NSURL URLWithString:[results stringForColumn:@"previewURL"]];

            // Get the fullscreen URL
            cameraEntity.fullscreenURL = [NSURL URLWithString:[results stringForColumn:@"fullscreenURL"]];

            // Get the preview format
            cameraEntity.previewFormat = [cameraEntity formatFromString:[results stringForColumn:@"previewFormat"]];

            // Get the fullscreen format
            cameraEntity.fullscreenFormat = [cameraEntity formatFromString:[results stringForColumn:@"fullscreenFormat"]];

            // Get the preview framerate
            cameraEntity.previewFramerate = [[results stringForColumn:@"previewFramerate"] floatValue];

            // Get the fullscreen framerate
            cameraEntity.fullscreenFramerate = [[results stringForColumn:@"fullscreenFramerate"] floatValue];

            // Get the identifier
            cameraEntity.identifier = [results intForColumn:@"id"];

            [cameraEntities addObject:cameraEntity];
        }
    }];

    return [cameraEntities copy];
}

- (NSArray *)securityEntities:(NSString *)roomName zone:(NSString *)zone service:(SAVService *)service
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_SECURITY"] || [self.zoneBlacklist containsObject:roomName])
    {
        return @[];
    }

    NSMutableArray *securityEntities = [NSMutableArray array];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(roomName), wildcardForNil(zone), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:self.queryManager.securityEntities withArgumentsInArray:arguments];

        while ([results next])
        {
            //--------------------------------------------------
            // Get the room, zone and the service from the
            // database since security entities may be
            // queried globally.
            //--------------------------------------------------
            NSString *entityRoom = [results stringForColumn:@"securityRoom"];
            if ([entityRoom isEqualToString:kSAVGlobalEnvZone])
            {
                entityRoom = roomName;
            }

            NSString *securityZone = [results stringForColumn:@"securityZone"];
            BOOL inGlobalZone = NO;
            if ([securityZone isEqualToString:kSAVGlobalEnvZone])
            {
                securityZone = @"Global";
                inGlobalZone = YES;
            }

            // Create the service
            SAVMutableService *securityService = [[SAVMutableService alloc] init];
            securityService.zoneName = [results stringForColumn:@"zone"];
            securityService.component = [results stringForColumn:@"component"];
            securityService.logicalComponent = [results stringForColumn:@"logicalComponent"];
            securityService.variantId = [results stringForColumn:@"serviceVariantID"];
            securityService.serviceId = [results stringForColumn:@"serviceType"];

            NSString *capabilities = [results stringForColumn:@"capabilities"];

            if (capabilities != nil)
            {
                securityService.capabilities = [capabilities componentsSeparatedByString:@","];
            }
            else
            {
                securityService.capabilities = nil;
            }

            // Create the entity
            SAVSecurityEntity *securityEntity =  [[SAVSecurityEntity alloc] initWithRoomName:entityRoom zoneName:securityZone service:securityService];
            securityEntity.inGlobalZone = inGlobalZone;

            // Get the name
            securityEntity.label = [results stringForColumn:@"securityName"];

            // Get the type of the entity
            securityEntity.type = [securityEntity typeFromString:[results stringForColumn:@"entityType"]];

            // Get the partition number
            securityEntity.partition = [results stringForColumn:@"partitionNumber"];

            // Get the zone (sensor) number
            securityEntity.sensor = [results stringForColumn:@"zoneNumber"];

            // Get bypass
            securityEntity.hasBypass = [results intForColumn:@"hasBypass"] == 1;

            // Get states
            securityEntity.statusState = [results stringForColumn:@"statusState"];
            securityEntity.bypassToggleState = [results stringForColumn:@"bypassToggleState"];
            securityEntity.bypassTextState = [results stringForColumn:@"bypassTextState"];

            // Get the identifier
            securityEntity.identifier = [results intForColumn:@"id"];

            [securityEntities addObject:securityEntity];
        }
    }];

    return [securityEntities copy];
}

- (NSArray *)zonesForRoom:(SAVRoom *)room filteredByService:(SAVService *)service
{
    if ([self.zoneBlacklist containsObject:room.roomId])
    {
        return @[];
    }

    NSMutableArray *zonesInRoom = [[NSMutableArray alloc] init];
    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(room.roomId), wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), wildcardForNil(service.connectorId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:[self.queryManager zonesInRoom] withArgumentsInArray:arguments];

        while ([results next])
        {
            SAVZone *tempZone = [[SAVZone alloc] init];

            tempZone.zoneName = [results stringForColumn:@"name"];

            [zonesInRoom addObject:tempZone];
        }
    }];

    return [zonesInRoom copy];
}

- (NSArray *)requests:(SAVService *)service onlyVisible:(BOOL)onlyvisible
{
    //-------------------------------------------------------------------
    // CBP TODO: Come back to this.
    //-------------------------------------------------------------------
    NSMutableArray *requestList = [[NSMutableArray alloc] init];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), wildcardForNil(service.connectorId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:onlyvisible ? [self.queryManager enabledRequests] : [self.queryManager requests] withArgumentsInArray:arguments];

        while ([results next])
        {
            SAVServiceRequest *request = [[SAVServiceRequest alloc] init];

            request.zoneName = [results stringForColumn:@"zone"];
            request.component = [results stringForColumn:@"component"];
            request.logicalComponent = [results stringForColumn:@"logicalComponent"];
            request.variantId = [results stringForColumn:@"serviceVariantID"];
            request.serviceId = [results stringForColumn:@"serviceType"];
            request.request = [results stringForColumn:@"request"];

            [requestList addObject:request];
        }
    }];

    return [requestList copy];
}

- (NSArray *)allRooms
{
    NSMutableArray *roomList = [[NSMutableArray alloc] init];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager allRooms] withArgumentsInArray:nil];

        while ([results next])
        {
            SAVRoom *room = [[SAVRoom alloc] init];

            room.roomId = [results stringForColumn:@"name"];
            room.hasLighting = [results boolForColumn:@"hasLights"];
            room.hasShades = [results boolForColumn:@"hasShades"];
            room.hasHVAC = [results boolForColumn:@"hasHVAC"];
            room.hasAV = [results boolForColumn:@"hasAV"];
            room.hasSecurity = [results boolForColumn:@"hasSecurity"];
            room.hasCameras = [results boolForColumn:@"hasCameras"];

            if (self.queryManager.queryVersion >= SCQueryVersion_13)
            {
                room.hasFans = [results boolForColumn:@"hasFans"];
            }
            
            NSString *groupId = [results stringForColumn:@"groupName"];
            if ([groupId length])
            {
                SAVRoomGroup *roomGroup = [[SAVRoomGroup alloc] init];
                roomGroup.groupId = [results stringForColumn:@"groupName"];

                room.group = roomGroup;
            }

            [roomList addObject:room];
        }
    }];

    return [roomList copy];
}

- (SAVRoom *)roomForRoomID:(NSString *)roomID
{
    NSParameterAssert(roomID);
    SAVRoom *room = [[SAVRoom alloc] init];

    __block BOOL foundARoom = NO;

    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager roomForRoomID] withArgumentsInArray:@[roomID]];

        while ([results next])
        {
            foundARoom = YES;
            room.roomId = [results stringForColumn:@"name"];
            room.hasLighting = [results boolForColumn:@"hasLights"];
            room.hasShades = [results boolForColumn:@"hasShades"];
            room.hasHVAC = [results boolForColumn:@"hasHVAC"];
            room.hasAV = [results boolForColumn:@"hasAV"];
            room.hasSecurity = [results boolForColumn:@"hasSecurity"];
            room.hasCameras = [results boolForColumn:@"hasCameras"];

            if (self.queryManager.queryVersion >= SCQueryVersion_13)
            {
                room.hasFans = [results boolForColumn:@"hasFans"];
            }
            
            NSString *groupId = [results stringForColumn:@"groupName"];
            if ([groupId length])
            {
                SAVRoomGroup *roomGroup = [[SAVRoomGroup alloc] init];
                roomGroup.groupId = [results stringForColumn:@"groupName"];

                room.group = roomGroup;
            }
        }
    }];

    if (!foundARoom)
    {
        room = nil;
    }

    return room;
}

- (NSArray *)servicesFilteredByServiceIDs:(NSArray *)services
{
    NSArray *results = @[];

    for (NSString *serviceID in services)
    {
        results = [results arrayByAddingObjectsFromArray:[self servicesFilteredByServiceID:serviceID]];
    }

    return results;
}

- (NSArray *)servicesFilteredByServiceID:(NSString *)serviceID
{
    NSParameterAssert(serviceID);
    SAVMutableService *service = [[SAVMutableService alloc] init];
    service.serviceId = serviceID;

    return [self servicesFilteredByService:service];
}

- (NSArray *)servicesFilteredByService:(SAVService *)service
{
    NSMutableArray *servicesList = [[NSMutableArray alloc] init];

    NSArray *arguments = [NSArray arrayWithObjects:wildcardForNil(service.zoneName), wildcardForNil(service.component), wildcardForNil(service.logicalComponent), wildcardForNil(service.variantId), wildcardForNil(service.serviceId), wildcardForNil(service.connectorId), nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:[self.queryManager services] withArgumentsInArray:arguments];

        while ([results next])
        {
            if ([results boolForColumn:@"show"] || self.queryManager.queryVersion < SCQueryVersion_2)
            {
                NSString *zoneName = [results stringForColumn:@"zone"];
                NSString *component = [results stringForColumn:@"component"];
                NSString *logicalComponent = [results stringForColumn:@"logicalComponent"];
                NSString *variantId = [results stringForColumn:@"serviceVariantID"];
                NSString *serviceId = [results stringForColumn:@"serviceType"];
                NSString *alias = [results stringForColumn:@"alias"];
                NSString *connectorId = [results stringForColumn:@"connectorID"];
                SAVServiceAVIOType avioType = [SAVService avioTypeForString:[results stringForColumn:@"avioType"]];
                SAVServiceOutputType outputType = [SAVService outputTypeForString:[results stringForColumn:@"avType"]];

                BOOL discreteVolume = NO;

                if (self.queryManager.queryVersion >= SCQueryVersion_4)
                {
                    discreteVolume = [results boolForColumn:@"discreteVolume"];
                }

                NSString *serviceAlias = nil;

                if (self.queryManager.queryVersion >= SCQueryVersion_10)
                {
                    serviceAlias = [results stringForColumn:@"serviceNameAlias"] ? [results stringForColumn:@"serviceNameAlias"] : alias;
                }
                else
                {
                    serviceAlias = [results stringForColumn:@"alias"];
                }

                NSString *capabilitiesString = [results stringForColumn:@"capabilities"];
                NSArray *capabilities = nil;

                if (capabilitiesString != nil)
                {
                    capabilities = [capabilitiesString componentsSeparatedByString:@","];
                }

                [servicesList addObject:[[SAVService alloc] initWithZone:zoneName
                                                               component:component
                                                        logicalComponent:logicalComponent
                                                               variantId:variantId
                                                               serviceId:serviceId
                                                                   alias:alias
                                                            serviceAlias:serviceAlias
                                                             connectorId:connectorId
                                                            capabilities:capabilities
                                                                avioType:avioType
                                                              outputType:outputType
                                                          discreteVolume:discreteVolume
                                                                  hidden:NO]];
            }
        }
    }];

    return [servicesList copy];
}

- (int)version
{
    //-------------------------------------------------------------------
    // Don't use self.databaseQueue here as it may not be initialized yet.
    //-------------------------------------------------------------------
    __block int version = 0;
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {

        FMResultSet *results = [db executeQuery:@"SELECT version FROM Version"];

        while ([results next])
        {
            version = [results intForColumn:@"version"];
        }
    }];

    return version;
}

- (NSArray *)stateStringsWithService:(SAVService *)service names:(NSArray *)stateNames
{
    //-------------------------------------------------------------------
    // CBP TODO: Come back to this
    //-------------------------------------------------------------------
    NSMutableArray *stateStrings = [[NSMutableArray alloc] init];

    NSString *resource = nil;
    __block NSString *scope = nil;

    if (_resourceMap != nil)
    {
        resource = [NSString stringWithFormat:@"%@", [_resourceMap objectForKey:service.serviceId]];
    }
    NSArray *arguments = [NSArray arrayWithObjects:[service serviceString], resource, nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:[self.queryManager stateScopes] withArgumentsInArray:arguments];

        while ([results next])
        {
            NSString *component = [results stringForColumn:@"component"];
            NSString *logicalComponent = [results stringForColumn:@"logicalComponent"];

            scope = [NSString stringWithFormat:@"%@.%@", component, logicalComponent];
        }

        if (!scope)
        {
            scope = [NSString stringWithFormat:@"%@.%@", service.component, service.logicalComponent];
        }

        for (NSString *stateName in stateNames)
        {
            [stateStrings addObject:[NSString stringWithFormat:@"%@.%@", scope, stateName]];
        }
    }];

    return [stateStrings copy];
}

- (NSString *)getLocalizedString:(NSString *)string
{
    return NSLocalizedString(string, nil);
}

- (NSArray *)HVACZonesInRooms
{
    NSMutableDictionary *hvacZones = [NSMutableDictionary dictionary];

    NSArray *arguments = [NSArray arrayWithObjects:@"Environmental", nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:@"SELECT Zones.name as zoneName, Rooms.name as roomName FROM ZoneRoomMap JOIN Zones ON Zones.id = ZoneRoomMap.zoneID JOIN Rooms on Rooms.id = ZoneRoomMap.roomID WHERE Zones.type = ? and Zones.id in (SELECT DISTINCT zoneID from HVACEntities) ORDER BY ZoneName, RoomName" withArgumentsInArray:arguments];

        while ([results next])
        {
            NSString *zoneName = [self getLocalizedString:[results stringForColumn:@"zoneName"]];
            NSString *roomName = [self getLocalizedString:[results stringForColumn:@"roomName"]];

            NSMutableDictionary *zoneDict = hvacZones[zoneName];

            if (!zoneDict)
            {
                zoneDict = [NSMutableDictionary dictionary];
                hvacZones[zoneName] = zoneDict;
            }

            zoneDict[@"zoneName"] = zoneName;

            NSMutableArray *roomsArray = zoneDict[@"rooms"];

            if (!roomsArray)
            {
                roomsArray = [NSMutableArray array];
                zoneDict[@"rooms"] = roomsArray;
            }

            [roomsArray addObject:roomName];
        }
    }];

    return [hvacZones allValues];
}

- (NSDictionary *)HVACRoomsInZones
{
    if ([self.serviceBlacklist containsObject:@"SVC_ENV_HVAC"])
    {
        return @{};
    }

    NSMutableDictionary *hvacZones = [NSMutableDictionary dictionary];

    NSArray *arguments = [NSArray arrayWithObjects:@"Environmental", nil];
    [[self createDatabaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:@"SELECT Zones.name as zoneName, Rooms.name as roomName FROM ZoneRoomMap JOIN Zones ON Zones.id = ZoneRoomMap.zoneID JOIN Rooms on Rooms.id = ZoneRoomMap.roomID WHERE Zones.type = ? and Zones.id in (SELECT DISTINCT zoneID from HVACEntities) ORDER BY ZoneName, RoomName" withArgumentsInArray:arguments];

        while ([results next])
        {
            NSString *zoneName = [self getLocalizedString:[results stringForColumn:@"zoneName"]];
            NSString *roomName = [self getLocalizedString:[results stringForColumn:@"roomName"]];

            if ([self.zoneBlacklist containsObject:roomName])
            {
                continue;
            }

            NSMutableArray *rooms = hvacZones[zoneName];
            if (!rooms)
            {
                rooms = [NSMutableArray array];
                hvacZones[zoneName] = rooms;
            }

            if (![rooms containsObject:roomName])
            {
                [rooms addObject:roomName];
            }
        }

    }];

    return [hvacZones copy];
}

- (NSString *)orderingKeyForService:(SAVService *)service
{
    NSString *key = nil;

    if (service.component && service.serviceId)
    {
        key = [NSString stringWithFormat:@"%@.%@.%@", SAVDynamicOrderingDictKey, service.component, service.serviceId];
    }

    return key;
}

- (void)saveOrdering:(NSDictionary *)ordering forService:(SAVService *)service
{
    if (service && ordering)
    {
        [[SAVSettings userSettings] setObject:ordering forKey:[self orderingKeyForService:service]];
        [[SAVSettings userSettings] synchronize];
    }
}

- (NSDictionary *)orderingForService:(SAVService *)service
{
    NSMutableDictionary *ordering = nil;

    if (service)
    {
        NSString *dynamicButtonsKey = [self orderingKeyForService:service];
        ordering = [[NSMutableDictionary alloc] initWithDictionary:[[SAVSettings userSettings] objectForKey:dynamicButtonsKey]];

        NSMutableArray *unorderedDynamicCommands = [[NSMutableArray alloc] initWithArray:service.dynamicCommands];
        [unorderedDynamicCommands addObjectsFromArray:service.customCommands];

        if (ordering[SAVShownObjectsArrayKey])
        {
            ordering[SAVShownObjectsArrayKey] = [ordering[SAVShownObjectsArrayKey] filteredArrayUsingBlock:^BOOL(NSString *requestString) {
                return ([unorderedDynamicCommands containsObject:requestString]);
            }];
        }

        for (NSString *cmd in [ordering objectForKey:SAVShownObjectsArrayKey])
        {
            [unorderedDynamicCommands removeObject:cmd];
        }

        for (NSString *cmd in [ordering objectForKey:SAVHiddenObjectsArrayKey])
        {
            [unorderedDynamicCommands removeObject:cmd];
        }

        if ([unorderedDynamicCommands count] > 0)
        {
            NSArray *defaultOrderedShownCommands = [self defaultShownDynamicCommandsForService:service];

            if (defaultOrderedShownCommands)
            {
                NSArray *newShownCommands = [defaultOrderedShownCommands filteredArrayUsingBlock:^BOOL(NSString *requestString) {
                    return ([unorderedDynamicCommands containsObject:requestString]);
                }];
                NSArray *newHiddenCommands = [unorderedDynamicCommands filteredArrayUsingBlock:^BOOL(NSString *requestString) {
                    return (![defaultOrderedShownCommands containsObject:requestString]);
                }];

                if (![ordering objectForKey:SAVShownObjectsArrayKey])
                {
                    ordering[SAVShownObjectsArrayKey] = newShownCommands;
                    ordering[SAVHiddenObjectsArrayKey] = newHiddenCommands;

                    if (defaultOrderedShownCommands)
                    {

                    }
                    else
                    {
                        [ordering setObject:unorderedDynamicCommands forKey:SAVShownObjectsArrayKey];
                    }
                }
                else
                {
                    if (!ordering[SAVShownObjectsArrayKey])
                    {
                        ordering[SAVShownObjectsArrayKey] = [NSMutableArray array];
                    }

                    if (!ordering[SAVHiddenObjectsArrayKey])
                    {
                        ordering[SAVHiddenObjectsArrayKey] = [NSMutableArray array];
                    }

                    ordering[SAVShownObjectsArrayKey] = [ordering[SAVShownObjectsArrayKey] arrayByAddingObjectsFromArray:newShownCommands];
                    ordering[SAVHiddenObjectsArrayKey] = [ordering[SAVHiddenObjectsArrayKey] arrayByAddingObjectsFromArray:newHiddenCommands];
                }
            }
            else
            {
                if (!ordering[SAVShownObjectsArrayKey])
                {
                    ordering[SAVShownObjectsArrayKey] = [NSMutableArray array];
                }

                ordering[SAVShownObjectsArrayKey] = [ordering[SAVShownObjectsArrayKey] arrayByAddingObjectsFromArray:unorderedDynamicCommands];
            }

            [[SAVSettings userSettings] setObject:ordering forKey:dynamicButtonsKey];
            [[SAVSettings userSettings] synchronize];
        }
    }

    return ordering;
}

- (NSArray *)defaultShownDynamicCommandsForService:(nonnull SAVService *)service
{
    SAVServiceTypeForDynamicCommandOrder serviceType = [[service class] SAVServiceTypeForServiceID:(NSString * __nonnull)(service.serviceId)];

    NSArray *defaultShownOrder;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (serviceType)
    {
        case SAVServiceTypeForDynamicCommandOrderTV:
        {
            defaultShownOrder = @[@"OnDemand",
                                  @"LastChannel",
                                  @"Menu",
                                  @"Guide",
                                  @"Exit",
                                  @"Help",
                                  @"Info",
                                  @"ATriangle",
                                  @"BSquare",
                                  @"CCircle",
                                  @"DDiamond",
                                  @"Red",
                                  @"Yellow",
                                  @"Green",
                                  @"Blue",
                                  ];
        }
            break;
        case SAVServiceTypeForDynamicCommandOrderDVDMedia:
        {
            defaultShownOrder = @[@"Setup",
                                  @"Angle",
                                  @"Zoom",
                                  @"Title",
                                  @"Menu",
                                  @"Open",
                                  @"Close",
                                  @"Return",
                                  @"Subtitle",
                                  @"Info",
                                  @"Home",
                                  ];
        }
            break;
        case SAVServiceTypeForDynamicCommandOrderSecurity:
        {
            defaultShownOrder = @[@"PanTiltZoom",
                                  @"TITLEoggleView"
                                  ];
        }
            break;
        case SAVServiceTypeForDynamicCommandOrderUnknown:
        default:
        {
            defaultShownOrder = nil;
        }
            break;
    }
#pragma clang diagnostic pop
    return defaultShownOrder;
}

- (NSString *)favoritesKeyForService:(SAVService *)service
{
    NSString *key = nil;

    if (service.serviceId)
    {
        key = [NSString stringWithFormat:@"%@.%@", SAVFavoritesListKey, [service.serviceId stringByReplacingOccurrencesOfString:@"AUDIO" withString:@""]];
    }

    return key;
}

- (void)saveFavorites:(NSArray *)favoritesArray forService:(SAVService *)service
{
    if (favoritesArray && service)
    {
        [[SAVSettings userSettings] setObject:favoritesArray forKey:[self favoritesKeyForService:service]];
        [[SAVSettings userSettings] synchronize];
    }
}

- (NSArray *)favoritesForService:(SAVService *)service
{   
    return [[SAVSettings userSettings] objectForKey:[self favoritesKeyForService:service]];
}

- (NSArray *)favoriteIconsForService:(SAVService *)service withSearchString:(NSString *)searchString
{
    //TODO: needs to fetch from host
    
    NSArray *iconNames = @[@"channel_icon_abc.png", @"channel_icon_cnn.png", @"channel_icon_espn.png", @"channel_icon_nbc.png", @"channel_icon_hbo.png", @"channel_icon_cbs.png"];
    /*
     if (searchString && [searchString length] > 0)
     {
     NSMutableArray *iconsMatching = [[NSMutableArray alloc] init];
     for (NSString *iconName in iconNames)
     {
     if ([iconName containsString:searchString])
     {
     [iconsMatching addObject:iconName];
     }
     }
     iconNames = iconsMatching;
     }
     NSMutableArray *icons = [[NSMutableArray alloc] initWithCapacity:[iconNames count]];
     for (NSString *iconName in iconNames)
     {
     [icons addObject:@{SAVFavoritesIconImageKey : [SAVUserDefaults getImageFromReference:iconName],
     SAVFavoritesImageRefKey : iconName}];
     }
     */
    return iconNames;
}

- (NSDictionary *)manifestSettings
{
    return [[Savant control] manifestForSystemUID:[Savant control].currentSystem.hostID][@"Settings"];
}

- (SAVDataMaybeBool)boolPropertyForManifestKey:(NSString *)key
{
    NSParameterAssert(key);
    NSNumber *number = [self manifestSettings][key];
    
    SAVDataMaybeBool value = SAVDataMaybeBoolNotPresent;
    
    if ([number isKindOfClass:[NSString class]] || [number isKindOfClass:[NSNumber class]])
    {
        if ([number boolValue])
        {
            value = SAVDataMaybeBoolYes;
        }
        else
        {
            value = SAVDataMaybeBoolNo;
        }
    }
    
    return value;
}

- (NSString *)stringPropertyForManifestKey:(NSString *)key
{
    NSParameterAssert(key);
    NSString *value = [self manifestSettings][key];
    
    if (![value isKindOfClass:[NSString class]])
    {
        value = nil;
    }
    
    return value;
}

@end
