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

#import "SAVQuery.h"
#include "sqlite3.h"

NSString *const SCInvalidArgumentException = @"SCInvalidArgumentException";

@interface SAVQueryV2 : SAVQuery

@end

@interface SAVQueryV3 : SAVQueryV2

@end

@interface SAVQueryV4 : SAVQueryV3

@end

@interface SAVQueryV5 : SAVQueryV4

@end

@interface SAVQueryV6 : SAVQueryV5

@end

@interface SAVQueryV7 : SAVQueryV6

@end

@interface SAVQueryV8 : SAVQueryV7

@end

@interface SAVQueryV9 : SAVQueryV8

@end

@interface SAVQueryV10 : SAVQueryV9

@end

@interface SAVQueryV11 : SAVQueryV10

@end

@interface SAVQueryV12 : SAVQueryV11

@end

@interface SAVQueryV13 : SAVQueryV12

@end

@interface SAVQuery ()

@property (nonatomic) SCQueryVersion queryVersion;

@end

@implementation SAVQuery

- (instancetype)initWithVersion:(SCQueryVersion)version
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (version)
    {
        case SCQueryVersion_1:
            self = [[SAVQuery alloc] init];
            break;
        case SCQueryVersion_2:
            self = [[SAVQueryV2 alloc] init];
            break;
        case SCQueryVersion_3:
            self = [[SAVQueryV3 alloc] init];
            break;
        case SCQueryVersion_4:
            self = [[SAVQueryV4 alloc] init];
            break;
        case SCQueryVersion_5:
            self = [[SAVQueryV5 alloc] init];
            break;
        case SCQueryVersion_6:
            self = [[SAVQueryV6 alloc] init];
            break;
        case SCQueryVersion_7:
            self = [[SAVQueryV7 alloc] init];
            break;
        case SCQueryVersion_8:
            self = [[SAVQueryV8 alloc] init];
            break;
        case SCQueryVersion_9:
            self = [[SAVQueryV9 alloc] init];
            break;
        case SCQueryVersion_10:
            self = [[SAVQueryV10 alloc] init];
            break;
        case SCQueryVersion_11:
            self = [[SAVQueryV11 alloc] init];
            break;
        case SCQueryVersion_12:
            self = [[SAVQueryV12 alloc] init];
            break;
        case SCQueryVersion_13:
        default:
            self = [[SAVQueryV13 alloc] init];
            break;
    }
#pragma clang diagnostic pop

    if (self)
    {
        self.queryVersion = version;
    }

    return self;
}

- (NSString *)stringFromSets:(NSArray *)sets
{
    NSMutableSet *set = [NSMutableSet set];

    for (NSSet *s in sets)
    {
        [set addObjectsFromArray:[s allObjects]];
    }

    if (![set count])
    {
        return @"()";
    }
    else
    {
        NSMutableString *string = [NSMutableString stringWithString:@"("];

        NSMutableArray *strings = [NSMutableArray array];

        for (NSString *s in set)
        {
            char *safeString = sqlite3_mprintf("%q", [s UTF8String]);

            if (safeString)
            {
                [strings addObject:[NSString stringWithFormat:@"'%@'", [NSString stringWithUTF8String:safeString]]];
            }
        }

        [string appendString:[strings componentsJoinedByString:@", "]];

        [string appendString:@")"];
        return [string copy];
    }
}

- (NSString *)serviceFilterQuery:(NSString *)columnName
{
    NSMutableString *string = [NSMutableString string];

    for (NSString *service in self.serviceBlacklist)
    {
        [string appendFormat:@"AND %@ NOT LIKE '%@%%' ", columnName, service];
    }

    return [string copy];
}

- (NSString *)version
{
    return @"SELECT version FROM Version";
}

- (NSString *)roomGroups
{
    return @"SELECT DISTINCT RoomGroups.name FROM Rooms "
    "LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
    "LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
    "ORDER BY RoomGroups.name IS NULL, RoomGroups.id";
}

- (NSString *)roomsInGroup
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"Where RoomGroups.name LIKE ?"
            @"AND Rooms.name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)ungroupedRooms
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName FROM Rooms "
            "LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            "LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            "Where RoomGroups.name ISNULL "
            "AND Rooms.name NOT IN %@ "
            "ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)allRoomIds
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT name FROM Rooms "
            @"WHERE name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)allHiddenRoomIds
{
    return @"";
}

- (NSString *)allRooms
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"WHERE Rooms.name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomForRoomID
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"WHERE Rooms.name NOT IN %@ "
            @"AND Rooms.name = ? "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)services
{
    return [NSString stringWithFormat:
    @"SELECT DISTINCT zone, component,logicalComponent,serviceVariantID,serviceType, alias, capabilities, avioType, connectorID, avType "
    "FROM ServiceImplementationServiceResources "
    "JOIN ServiceOrder ON ServiceImplementationServiceResources.id = ServiceOrder.serviceID "
    "LEFT JOIN ServiceCapabilities ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
    "WHERE zone LIKE ? AND zone NOT IN %@ %@ AND component LIKE ? AND logicalComponent LIKE ? AND serviceVariantID LIKE ? AND connectorID LIKE ? "
    "AND pathOrder=0 ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)allServices
{
    return [NSString stringWithFormat:
            @"SELECT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceOrder "
            @"ON ServiceImplementationServiceResources.id = ServiceOrder.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE pathOrder=0 "
            @"AND zone NOT IN %@ "
            @"%@"
            @"GROUP BY component,logicalComponent, serviceType "
            @"ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)requests
{
    return
    @"SELECT DISTINCT zone,component,logicalComponent,serviceVariantID,serviceType,request "
    "FROM ServiceImplementationRequests SIRequests "
    "JOIN ServiceImplementationRequestMap Map "
    "ON SIRequests.id = Map.ServiceImplementationRequests_id "
    "JOIN ServiceImplementationZonedService service "
    "ON service.id = Map.ServiceImplementationZonedService_id "
    "WHERE zone LIKE ? "
    "AND component LIKE ? "
    "AND logicalComponent LIKE ? "
    "AND serviceVariantID LIKE ? "
    "AND serviceType LIKE ? "
    "AND isInterService == 0 ";
}

- (NSString *)enabledRequests
{
    return
    @"SELECT DISTINCT zone,component,logicalComponent,serviceVariantID,serviceType,request "
    "FROM ServiceImplementationRequests SIRequests "
    "JOIN ServiceImplementationRequestMap Map "
    "ON SIRequests.id = Map.ServiceImplementationRequests_id "
    "JOIN ServiceImplementationRequestMapEnabled Enable "
    "ON Map.id = Enable.requestMapID "
    "JOIN ServiceImplementationZonedService service "
    "ON service.id = Map.ServiceImplementationZonedService_id "
    "WHERE zone LIKE ? "
    "AND component LIKE ? "
    "AND logicalComponent LIKE ? "
    "AND serviceVariantID LIKE ? "
    "AND serviceType LIKE ? "
    "AND enabled == 1 "
    "AND isInterService == 0 ";
}

- (NSString *)stateScopes
{
    return
    @"SELECT DISTINCT component, logicalComponent "
    "FROM ServiceImplementationServiceResources "
    "WHERE service=? AND resourceType=? "
    "LIMIT 1";
}

- (NSString *)zonesInRoom
{
    return
    [NSString stringWithFormat:@"SELECT Zones.name,services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,services.alias, services.avioType, services.connectorID, services.avType "
     "FROM Rooms "
     "%@ "
     "WHERE Rooms.name LIKE ? "
     "AND services.zone LIKE ? "
     "AND services.component LIKE ? "
     "AND services.logicalComponent LIKE ? "
     "AND services.serviceVariantID LIKE ? "
     "AND services.serviceType LIKE ? "
     "AND services.connectorID LIKE ?"
     "GROUP BY zones.name", [self zoneJoin]];
}

- (NSString *)zonesWhichHaveService
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT name FROM rooms "
            @"JOIN ServiceImplementationServiceResources services "
            @"ON services.zone = rooms.name "
            @"AND name NOT IN %@ "
            @"AND services.component LIKE ? "
            @"AND services.logicalComponent LIKE ? "
            @"AND services.serviceType LIKE ? "
            @"AND services.serviceVariantID LIKE ? "
            @"AND services.connectorID LIKE ? "
            @"AND services.pathOrder = 0",
            [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)servicesWhichHaveZones
{
    //-------------------------------------------------------------------
    // Does not conform to ACL yet
    //-------------------------------------------------------------------
    return
    [NSString stringWithFormat:@"SELECT services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,services.alias,capabilities.capabilities,services.avioType, services.connectorID, services.avType "
    "FROM Rooms %@ "
    "LEFT JOIN ServiceCapabilities capabilities "
    "ON services.id = capabilities.serviceID "
    "WHERE Rooms.name LIKE ? "
    "AND services.zone LIKE ? "
    "AND services.component LIKE ? "
    "AND services.logicalComponent LIKE ? "
    "AND services.serviceVariantID LIKE ? "
    "AND services.serviceType LIKE ? "
    "AND services.connectorID LIKE ? ", [self zoneJoin]];
}

- (NSString *)hvacEntities
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT hvac.name,hvac.addresses,hvac.temperatureSetPoints,hvac.humiditySetPoints,"
            "hvac.heat,hvac.cool,hvac.humidify,hvac.dehumidify,"
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities,services.zone as roomName,zones.name as zoneName "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN HVACEntities hvac "
            "ON hvac.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY hvac.id ",
            [self zoneJoin]];
}

- (NSString *)poolAndSpaEntities
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT poolandspa.name,poolandspa.entityType,poolandspa.auxiliaryNumber,"
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN PoolAndSpaEntities poolandspa "
            "ON poolandspa.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "ORDER BY poolandspa.id",
            [self zoneJoin]];
}

- (NSString *)lightingEntities
{
    return [NSString stringWithFormat:
            @"SELECT light.name,light.addresses,light.entityType,light.pressCommand, "
            "light.holdCommand, light.releaseCommand, light.togglePressCommand, "
            "light.toggleHoldCommand, light.toggleReleaseCommand, light.dimmerCommand, "
            "light.fadeTime,light.delayTime, light.stateName, light.id, "
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN LightEntities light "
            "ON light.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY light.id "
            "ORDER BY light.id",
            [self zoneJoin]];
}

- (NSString *)shadeEntities
{
    return [NSString stringWithFormat:
            @"SELECT shade.name,shade.addresses,shade.entityType,shade.stateName,shade.pressCommand, "
            "shade.holdCommand, shade.releaseCommand, shade.togglePressCommand, "
            "shade.toggleHoldCommand, shade.toggleReleaseCommand, "
            "shade.fadeTime, shade.delayTime, shade.id, "
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN ShadeEntities shade "
            "ON shade.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY shade.id "
            "ORDER BY shade.id",
            [self zoneJoin]];
}

- (NSString *)cameraEntities
{
    return @"";
}

- (NSString *)securityEntities
{
    return @"";
}

#pragma mark - Internal

- (NSString *)zoneJoin
{
    return @"JOIN ZoneRoomMap "
    "ON Rooms.id = ZoneRoomMap.roomID "
    "JOIN Zones "
    "ON  Zones.id = ZoneRoomMap.zoneID "
    "JOIN  ZoneConfigComponents comps "
    "ON Zones.componentID = comps.id "
    "JOIN ServiceImplementationServiceResources services "
    "ON services.component = comps.component ";
}

@end

@implementation SAVQueryV2

- (NSString *)services
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE zone LIKE ? "
            @"AND zone NOT IN %@ "
            @"%@"
            @"AND component LIKE ? "
            @"AND logicalComponent LIKE ? "
            @"AND serviceVariantID LIKE ? "
            @"AND serviceType LIKE ? "
            @"AND connectorID LIKE ? "
            @"AND pathOrder=0 "
            @"ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)allServices
{
    return [NSString stringWithFormat:
            @"SELECT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show, avioType, connectorID, avType  "
            @"FROM ServiceImplementationServiceResources  "
            @"JOIN ServiceInfo  "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID  "
            @"LEFT JOIN ServiceCapabilities  "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID  "
            @"WHERE pathOrder=0  "
            @"AND zone NOT IN %@ "
            @"%@"
            @"GROUP BY component,logicalComponent, serviceType "
            @"ORDER BY serviceOrder ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)enabledRequests
{
    return @"SELECT DISTINCT zone,component,logicalComponent,serviceVariantID,serviceType,request "
    "FROM ServiceImplementationRequests SIRequests "
    "JOIN ServiceImplementationRequestMap Map "
    "ON SIRequests.id = Map.ServiceImplementationRequests_id "
    "JOIN ServiceImplementationRequestMapEnabled Enable "
    "ON Map.id = Enable.requestMapID "
    "JOIN ServiceImplementationZonedService service "
    "ON service.id = Map.ServiceImplementationZonedService_id "
    "WHERE zone LIKE ? "
    "AND component LIKE ? "
    "AND logicalComponent LIKE ? "
    "AND serviceVariantID LIKE ? "
    "AND serviceType LIKE ? "
    "AND enabled == 1 "
    "AND isInterService == 0 ";
}

- (NSString *)servicesWhichHaveZones
{
    return [NSString stringWithFormat:
            @"SELECT services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,services.alias,services.show,capabilities.capabilities, services.avioType, services.connectorID, services.avType, show "
            "FROM Rooms %@"
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id =  ServiceCapabilities.serviceID "
            "WHERE Rooms.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "AND services.connectorID LIKE ? "
            "AND services.pathOrder = 0",
            [self zoneJoin]];
}

- (NSString *)zonesWhichHaveService
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT name, show FROM rooms "
            @"JOIN ServiceImplementationServiceResources services "
            @"ON services.zone = rooms.name "
            @"JOIN ServiceInfo "
            @"ON services.id = ServiceInfo.serviceID "
            @"AND name NOT IN %@ "
            @"AND services.component LIKE ? "
            @"AND services.logicalComponent LIKE ? "
            @"AND services.serviceType LIKE ? "
            @"AND services.serviceVariantID LIKE ? "
            @"AND services.connectorID LIKE ? "
            @"AND services.pathOrder = 0",
            [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

@end

@implementation SAVQueryV3

- (NSString *)allRooms
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"WHERE Rooms.name NOT IN %@", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomForRoomID
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"WHERE Rooms.name NOT IN %@ "
            @"AND Rooms.name = ? ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)ungroupedRooms
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            "LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            "LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            "LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            "Where RoomGroups.name ISNULL "
            "AND Rooms.name NOT IN %@"
            "ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomsInGroup
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"Where RoomGroups.name LIKE ?  "
            @"AND Rooms.name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)services
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show,hasZones, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE zone LIKE ? "
            @"AND zone NOT IN %@ "
            @"%@"
            @"AND component LIKE ? "
            @"AND logicalComponent LIKE ? "
            @"AND serviceVariantID LIKE ? "
            @"AND serviceType LIKE ? "
            @"AND connectorID LIKE ? "
            @"AND pathOrder=0 "
            @"ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)allServices
{
    return [NSString stringWithFormat:
            @"SELECT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show,hasZones, avioType, connectorID, avType "
            "FROM ServiceImplementationServiceResources "
            "JOIN ServiceInfo "
            "ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            "LEFT JOIN ServiceCapabilities "
            "ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            "WHERE pathOrder=0 "
            @"AND zone NOT IN %@ "
            @"%@"
            "GROUP BY component,logicalComponent, serviceType "
            "ORDER BY serviceOrder ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)cameraEntities
{
    return [NSString stringWithFormat:
            @"SELECT camera.name AS cameraName,entityType,previewURL,fullscreenURL,previewFormat,fullscreenFormat, "
            "previewFramerate,fullscreenFramerate,Zones.name AS cameraZone, "
            "services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,capabilities.capabilities,Rooms.name AS cameraRoom,camera.id "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN CameraEntities camera "
            "ON camera.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY camera.id,Zones.name "
            "ORDER BY Zones.name,camera.name ",
            [self zoneJoin]];
}

- (NSString *)securityEntities
{
    return [NSString stringWithFormat:
            @"SELECT security.name AS securityName,entityType,partitionNumber,zoneNumber,hasBypass, "
            "statusState,bypassToggleState,bypassTextState,Zones.name AS securityZone, "
            "services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,capabilities.capabilities,Rooms.name AS securityRoom,security.id "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN SecuritySystemEntities security "
            "ON security.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND services.zone NOT IN %@ "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY security.id ,Zones.name "
            "ORDER BY Zones.name,security.name ",
            [self zoneJoin], [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

@end

@implementation SAVQueryV4

- (NSString *)services
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT "
            @"zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show,hasZones,discreteVolume, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE zone LIKE ? "
            @"AND zone NOT IN %@ "
            @"%@"
            @"AND component LIKE ? "
            @"AND logicalComponent LIKE ? "
            @"AND serviceVariantID LIKE ? "
            @"AND serviceType LIKE ? "
            @"AND connectorID LIKE ? "
            @"AND pathOrder=0 "
            @"ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)allServices
{
    return [NSString stringWithFormat:
            @"SELECT zone,component,logicalComponent,serviceVariantID,serviceType,alias,capabilities,show,hasZones,discreteVolume, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE pathOrder=0 "
            @"AND zone NOT IN %@ "
            @"%@"
            @"GROUP BY component,logicalComponent, serviceType "
            @"ORDER BY serviceOrder ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)servicesWhichHaveZones
{
    return [NSString stringWithFormat:
            @"SELECT services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,services.alias,services.show,capabilities.capabilities, services.avioType, services.connectorID, services.avType, show, services.discreteVolume "
            "FROM Rooms %@"
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id =  ServiceCapabilities.serviceID "
            "WHERE Rooms.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "AND services.connectorID LIKE ? "
            "AND services.pathOrder = 0",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV5

- (NSString *)lightingEntities
{
    return [NSString stringWithFormat:
            @"SELECT light.name,light.addresses,light.entityType,light.pressCommand, "
            "light.holdCommand, light.releaseCommand, light.togglePressCommand, "
            "light.toggleHoldCommand, light.toggleReleaseCommand, light.dimmerCommand, "
            "light.fadeTime,light.delayTime, light.stateName, light.id, light.isSceneable, "
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN LightEntities light "
            "ON light.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY light.id "
            "ORDER BY light.id",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV6

- (NSString *)shadeEntities
{
    return [NSString stringWithFormat:
            @"SELECT shade.name,shade.addresses,shade.entityType,shade.stateName,shade.pressCommand, "
            "shade.holdCommand, shade.releaseCommand, shade.togglePressCommand, "
            "shade.toggleHoldCommand, shade.toggleReleaseCommand, "
            "shade.fadeTime, shade.delayTime, shade.id, shade.isSceneable, "
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN ShadeEntities shade "
            "ON shade.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY shade.id "
            "ORDER BY shade.id",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV7

- (NSString *)ungroupedRooms
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, Rooms.shown, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            "LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            "LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            "LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            "Where RoomGroups.name ISNULL "
            "AND Rooms.name NOT IN %@"
            "ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomsInGroup
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, Rooms.shown, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"Where RoomGroups.name LIKE ?  "
            @"AND Rooms.name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)allHiddenRoomIds
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT name FROM Rooms "
            @"WHERE name NOT IN %@ "
            @"AND shown = 0 "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist]]];
}

@end

@implementation SAVQueryV8

- (NSString *)cameraEntities
{
    return [NSString stringWithFormat:
            @"SELECT camera.name AS cameraName,entityType,previewURL,fullscreenURL,previewFormat,fullscreenFormat, "
            "previewFramerate,fullscreenFramerate,Zones.name AS cameraZone, "
            "services.zone,services.component,Zones.logicalComponent,services.serviceVariantID,services.serviceType,capabilities.capabilities,Rooms.name AS cameraRoom,camera.id "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN CameraEntities camera "
            "ON camera.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY camera.id,Zones.name "
            "ORDER BY Zones.name,camera.name ",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV9

@end

@implementation SAVQueryV10

- (NSString *)services
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT "
            @"zone,component,logicalComponent,serviceVariantID,serviceType,alias,serviceNameAlias,capabilities,show,hasZones,discreteVolume, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE zone LIKE ? "
            @"AND zone NOT IN %@ "
            @"%@"
            @"AND component LIKE ? "
            @"AND logicalComponent LIKE ? "
            @"AND serviceVariantID LIKE ? "
            @"AND serviceType LIKE ? "
            @"AND connectorID LIKE ? "
            @"AND pathOrder=0 "
            @"ORDER BY serviceOrder", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)allServices
{
    return [NSString stringWithFormat:
            @"SELECT zone,component,logicalComponent,serviceVariantID,serviceType,alias,serviceNameAlias,capabilities,show,hasZones,discreteVolume, avioType, connectorID, avType "
            @"FROM ServiceImplementationServiceResources "
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            @"LEFT JOIN ServiceCapabilities "
            @"ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            @"WHERE pathOrder=0 "
            @"AND zone NOT IN %@ "
            @"%@"
            @"GROUP BY component,logicalComponent, serviceType "
            @"ORDER BY serviceOrder ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]], [self serviceFilterQuery:@"serviceType"]];
}

- (NSString *)servicesWhichHaveZones
{
    return [NSString stringWithFormat:
            @"SELECT services.zone,services.component,services.logicalComponent,services.serviceVariantID,services.serviceType,services.alias,services.serviceNameAlias,services.show,capabilities.capabilities, services.avioType, services.connectorID, services.avType, show "
            "FROM Rooms %@"
            @"JOIN ServiceInfo "
            @"ON ServiceImplementationServiceResources.id = ServiceInfo.serviceID "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON ServiceImplementationServiceResources.id =  ServiceCapabilities.serviceID "
            "WHERE Rooms.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "AND services.connectorID LIKE ? "
            "AND services.pathOrder = 0",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV11

- (NSString *)hvacEntities
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT hvac.name,hvac.addresses,hvac.temperatureSetPoints,hvac.humiditySetPoints,"
            "hvac.heat,hvac.cool,hvac.humidify,hvac.dehumidify,hvac.history,"
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities,services.zone as roomName,zones.name as zoneName "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN HVACEntities hvac "
            "ON hvac.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY hvac.id ",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV12

- (NSString *)hvacEntities
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT hvac.name,hvac.addresses,hvac.temperatureSetPoints,hvac.humiditySetPoints,"
            "hvac.heat,hvac.cool,hvac.auto,hvac.humidify,hvac.dehumidify,hvac.history,"
            "services.component,services.logicalComponent,services.serviceType as serviceID,capabilities.capabilities,services.zone as roomName,zones.name as zoneName "
            "FROM Rooms %@ "
            "LEFT JOIN ServiceCapabilities capabilities "
            "ON services.id = capabilities.serviceID "
            "JOIN HVACEntities hvac "
            "ON hvac.zoneID = Zones.id "
            "WHERE Rooms.name LIKE ? "
            "AND Zones.name LIKE ? "
            "AND services.zone LIKE ? "
            "AND services.component LIKE ? "
            "AND services.logicalComponent LIKE ? "
            "AND services.serviceVariantID LIKE ? "
            "AND services.serviceType LIKE ? "
            "GROUP BY hvac.id ",
            [self zoneJoin]];
}

@end

@implementation SAVQueryV13

- (NSString *)allRooms
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasFans,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"WHERE Rooms.name NOT IN %@", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomForRoomID
{
    return [NSString stringWithFormat:
            @"SELECT DISTINCT Rooms.name, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasFans,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"WHERE Rooms.name NOT IN %@ "
            @"AND Rooms.name = ? ", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)ungroupedRooms
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, Rooms.shown, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasFans,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            "LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            "LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            "LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            "Where RoomGroups.name ISNULL "
            "AND Rooms.name NOT IN %@"
            "ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

- (NSString *)roomsInGroup
{
    return [NSString stringWithFormat:@"SELECT DISTINCT Rooms.name, Rooms.shown, RoomGroups.name AS groupName,hasAV,hasLights,hasShades,hasFans,hasHVAC,hasSecurity,hasCameras FROM Rooms "
            @"LEFT JOIN RoomGroupMap ON Rooms.id = RoomGroupMap.roomID "
            @"LEFT JOIN RoomGroups ON RoomGroups.id = RoomGroupMap.groupID "
            @"LEFT JOIN RoomCapabilities ON Rooms.id = RoomCapabilities.roomID "
            @"Where RoomGroups.name LIKE ?  "
            @"AND Rooms.name NOT IN %@ "
            @"ORDER BY Rooms.id", [self stringFromSets:@[self.zoneBlacklist, self.hiddenRooms]]];
}

@end