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
@import UIKit;
#import "SAVRoom.h"
#import "SAVService.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SAVDataMaybeBool)
{
    SAVDataMaybeBoolNotPresent = 0,
    SAVDataMaybeBoolYes,
    SAVDataMaybeBoolNo
};

extern NSString *const kSystemSQLDataFile;

extern NSString *const SAVFavoritesIconNameKey;
extern NSString *const SAVFavoritesIconImageKey;

extern NSString *const SAVFavoriteNumberKey;
extern NSString *const SAVFavoriteImageKey;
extern NSString *const SAVFavoriteDescriptionKey;

extern NSString *const SAVShownObjectsArrayKey;
extern NSString *const SAVHiddenObjectsArrayKey;

@interface SAVData : NSObject

@property (readonly) NSString *TAG;
@property (readonly) NSString *databasePath;
@property (readonly, atomic) int version;
@property NSDictionary *resourceMap;
@property (readonly) NSSet *serviceBlacklist;
@property (readonly) NSSet *zoneBlacklist;

/**
 *  Returns an array of room objects from the database.
 *
 *  @return NSArray Array of room objects.
 */
- (NSArray *)allRooms;

/**
 *  Returns a full room given a room name.
 *
 *  @return A full room, or nil.
 */
- (SAVRoom *)roomForRoomID:(NSString *)roomID;

/**
 *  Returns a list of services filtered by a list of services.
 *
 *  @param services The 'filtering' services.
 *
 *  @return A list of filtered services.
 */
- (NSArray *)servicesFilteredByServiceIDs:(NSArray *)services;

/**
 *  Returns a list of services filtered by a list of services.
 *
 *  @param serviceID The 'filtering' services.
 *
 *  @return A list of filtered services.
 */
- (NSArray *)servicesFilteredByServiceID:(NSString *)serviceID;

/**
 *  Returns a list of services filtered with the given service.
 *
 *  @param service The 'filtering' service.
 *
 *  @return A list of filtered services.
 */
- (NSArray *)servicesFilteredByService:(nullable SAVService *)service;

/**
 * Fetches the service requests which match the parameters specified in the service argument. For example you may set the zone field of the service object and leave other fields as null to return all service requests in that zone.
 *
 *  @param service     A service object which contains the service parameters to filter against. If null then all service requests will be returned.
 *  @param onlyVisible If true then this will only return service requests which have been configured to be visible to the user.
 *
 *  @return A list of service requests matching the search criteria.
 */
- (NSArray *)requests:(nullable SAVService *)service onlyVisible:(BOOL)onlyVisible;

/**
 *  Fetches the service requests which match the parameters specified in the
 * service argument. For example you may set the zone field of the service
 * object and leave other fields as null to return all service requests in
 * that zone.
 *
 *  @param service A service object which contains the service parameters to
 *            filter against. If null then all service requests will be
 *            returned.
 *
 *  @return A list of service requests matching the search criteria.
 */
- (NSArray *)requestsFilteredByService:(nullable SAVService *)service;

/**
 *  Gets all of the zones associated with the room and service. Use this
 * method to get environmental (or tiling, etc) zones associated with a
 * room.
 *
 *  @param room    The room to scope the query to. Null will result in all rooms
 *            being queried.
 *  @param service The service to scope the query to. Null for service will
 *            wild-card all fields, null for any individual field will
 *            wild-card just that field.
 *
 *  @return NSArray An array of string representing the zones.
 */
- (NSArray *)zonesForRoom:(SAVRoom *)room filteredByService:(SAVService *)service;

/**
 *  A list of containing rooms for a given service.
 *
 *  @param service service object
 *
 *  @return rooms
 */
- (NSArray *)zonesWithService:(SAVService *)service;

/**
 *  Groups a list of service objects into service groups
 *
 *  @param services An array of services to group.
 *
 *  @return an array of service groups
 */
- (NSArray *)serviceGroupsForServices:(NSArray *)services;

/**
 *  An array of all available service groups
 *
 *  @return an array of service groups
 */
- (NSArray *)allServiceGroups;

/**
 *  An array of all available unique services across all rooms.
 *
 *  @return an array of services
 */
- (NSArray *)allServices;

/**
 *  Gets all of the services which have zones associated with them. Use this
 * method to obtain a list of environmental (or tiling, etc) services which
 * have zones defined in the current room.
 *
 *  @param room    The room to scope the query to. Null will result in all rooms
 *            being queried.
 *  @param service The service to scope the query to. Null for service will
 *            wild-card all fields, null for any individual field will
 *            wild-card just that field.
 *
 *  @return A list of services which have zones.
 */
- (NSArray *)servicesWithZones:(nullable SAVRoom *)room service:(nullable SAVService *)service;

/**
 *  Call for getting all the rooms within all HVAC zones
 *
 *  @return NSArray of NSDictionaries representing all the HVAC zones and the rooms within each zone
 */
- (NSArray *)HVACZonesInRooms;

/**
 *  Call for getting all the rooms within all HVAC zones
 *
 *  @return NSDictionary of rooms lists, keyed by zone name.
 */
- (NSDictionary *)HVACRoomsInZones;

/**
 *  Returns all the light entities for the given room.
 *
 *  @param room The room.
 *
 *  @return All the light entities for the given room.
 */
- (NSArray *)lightEntitiesForRoom:(nullable NSString *)room;

/**
 *  Returns all the shade entities for the given room.
 *
 *  @param zone The room.
 *
 *  @return All the shade entities for the given room.
 */
- (NSArray *)shadeEntitiesForRoom:(nullable NSString *)zone;

/**
 *  Returns all the shade entities for the given room.
 *
 *  @param zone The room.
 *
 *  @return All the shade entities for the given room.
 */
- (NSArray *)HVACEntitiesForRoom:(nullable NSString *)zone;

/**
 *  Call for getting HVAC entities.
 *
 *  @param roomId  The room to scope the query to. Null will result in all rooms being queried.
 *  @param zone    The zone for the room.
 *  @param service The service for the entity.
 *
 *  @return NSArray Array of HVAC entities.
 */
- (NSArray *)HVACEntities:(nullable NSString *)roomId zone:(nullable NSString *)zone service:(nullable SAVService *)service;

/**
 *  Call for getting HVAC entities.
 *
 *  @param roomName The room to scope the query to. Null will result in all rooms being queried.
 *  @param zone     The zone for the room.
 *  @param service  The service for the entity.
 *
 *  @return NSArray Array of Pool entities.
 */
- (NSArray *)poolEntities:(nullable NSString *)roomName zone:(nullable NSString *)zone service:(nullable SAVService *)service;

/**
 *  Call for getting camera entities. Used internally only.
 *
 *  @param roomId  The room to scope the query to. Null will result in all rooms
 *            being queried.
 *  @param zone    The zone for the room.
 *  @param service The service for the entity.
 *
 *  @return NSArray Array of camera entities.
 */
- (NSArray *)cameraEntities:(nullable NSString *)roomId zone:(nullable NSString *)zone service:(nullable SAVService *)service;

/**
 *  Call for getting security entities. Used internally only.
 *
 *  @param roomId  The room to scope the query to. Null will result in all rooms
 *            being queried.
 *  @param zone    The zone for the room.
 *  @param service The service for the entity.
 *
 *  @return NSArray Array of security entities.
 */
- (NSArray *)securityEntities:(NSString *)roomId zone:(NSString *)zone service:(SAVService *)service;

/**
 *  Sorts an array of room ids based on the internal sorting.
 *
 *  @param rooms An array of room ids.
 *
 *  @return A sorted array of room ids.
 */
- (NSArray *)sortedRoomsWithRooms:(NSArray *)rooms;

/**
 *  Fetches a list of all rooms IDs. The room ID is suitable to be used
 * in queries which require a room but will not be localized.
 *
 *  @return A list of all rooms.
 */
- (NSArray *)allRoomIds;

/**
 *  Fetches a list of all room groups.
 *
 *  @return A list of room groups.
 */
- (NSArray *)allRoomGroups;

/**
 *  Returns the rooms within a group. If the group isn't specified this will
 * return all rooms.
 *
 *  @param roomGroup The room group or null.
 *
 *  @return A list of rooms in the group.
 */
- (NSArray *)roomsInRoomGroup:(SAVRoomGroup *)roomGroup;

/**
 *  Translates the provided state names into their fully qualified state
 * strings.
 *
 *  @param service    The service in which the states exist.
 *  @param stateNames A list of state names. Note state strings are typically in the
 *            form scope.name.
 *
 *  @return  A list of fully qualified state strings. The order will match the
 *         input array.
 */
- (NSArray *)stateStringsWithService:(SAVService *)service names:(NSArray *)stateNames;

/**
 *  This will set the service to resource map object. This will be used in
 * {@link SavantData#getStateStrings(Service, List)} to translate state
 * names.
 *
 *  @param json  A json object with each key being the service and each value
 *            being the resource.
 */
- (void)setServiceToResourceMap:(NSData *)json;

/**
 *  Returns the version in the database.
 *
 *  @return int the version of the database.
 */
- (int)version;

/**
 *  A helper to fetch the ordering scope for a given service.
 *
 *  @param service a service object
 *
 *  @return The ordering scope for a given service.
 */
- (NSString *)orderingKeyForService:(SAVService *)service;

/**
 *  Wrapper method that call the SAVUserDefaults method to set the order of the dynamic buttons and buttons that will be hidden
 *
 *  @param ordering NSDictionary
                    NSArray of commands for the service and component in the order they should appear.
 *                  NSArray of commands for the service and component that should be hidden.
 *  @param service              SAVService object that the order and hidden dynamic commands are set for. If serviceId or component are nil the method returns with out saving to host or SAVUserDefaults.
 *
 */
- (void)saveOrdering:(NSDictionary *)ordering forService:(SAVService *)service;

/**
 *  Returns a dictionary that has 0 - 2 arrays for the keys SAVShownObjectsArrayKey and SAVHiddenObjectsArrayKey.
 *  Wrapper method that call the SAVUserDefaults method to fetch the order of the dynamic buttons and buttons that will be hidden
 *
 *  @param service              SAVService object that the order and hidden dynamic commands are set for. If serviceId or component are nil the method returns nil.
 *
 *  @return NSDictionary with 0-2 arrays for the order of buttons in the Dynamic button collection and an array of hidden items.  both may not be set and in that case it would return an empty dictionary
 *
 */
- (NSDictionary *)orderingForService:(SAVService *)service;

/**
 *  A helper to fetch the favorites scope for a given service.
 *
 *  @param service a service object
 *
 *  @return The favorites scope for a given service.
 */
- (NSString *)favoritesKeyForService:(SAVService *)service;

/**
 *  Wrapper method that call the SAVUserDefaults method to set Favorites
 *
 *  @param favoritesArray NSArray
    NSArray of favorites this will destroy any existing favorites 
 *  @param service              SAVService object that the order and hidden dynamic commands are set for. If serviceId or component are nil the method returns with out saving to host or SAVUserDefaults.
 *
 */
- (void)saveFavorites:(NSArray *)favoritesArray forService:(SAVService *)service;

/**
 *  Returns an array of the favorites
 *  Wrapper method that call the SAVUserDefaults method to fetch the order of the dynamic buttons and buttons that will be hidden
 *
 *  @param service              SAVService object that the order and hidden dynamic commands are set for. If serviceId or component are nil the method returns nil.
 *
 *  @return     NSArray of favorites this will destroy any existing favorites
    if no favorites are set nil will be returned
 *
 */
- (NSArray *)favoritesForService:(SAVService *)service;

/**
 *  Returns a dictionary that has 0 - 2 arrays for the keys SAVShownObjectsArrayKey and SAVHiddenObjectsArrayKey.
 *  Wrapper method that call the SAVUserDefaults method to fetch defualt Icon Images for the for the favorites
 *
 *  @param service              SAVService object that the Favorites apply to
 *
 *  @return an array of NSDictionary with the keys SAVFavoritesIconImageKey, SAVFavoritesIconNameKey
 *
 */
- (NSArray *)favoriteIconsForService:(nullable SAVService *)service withSearchString:(NSString *)searchString;

/**
 *  Returns a maybe bool for a property in the uimanifest file.
 *
 *  @param key The key.
 *
 *  @return A SAVDataMaybeBool represeting not present, YES or NO.
 */
- (SAVDataMaybeBool)boolPropertyForManifestKey:(NSString *)key;

- (NSString *)stringPropertyForManifestKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
