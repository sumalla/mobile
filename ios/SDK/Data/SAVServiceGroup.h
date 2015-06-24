//
//  SAVServiceGroup.h
//  SavantControl
//
//  Created by Nathan Trapp on 10/9/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

typedef NS_OPTIONS(NSInteger, SAVServiceOutputType)
{
    SAVServiceOutputTypeNone = 0,
    SAVServiceOutputTypeAudio = 1 << 0,
    SAVServiceOutputTypeAudioVideo = 1 << 1
};

typedef NS_ENUM(NSInteger, SAVServiceAVIOType)
{
    SAVServiceAVIOTypeUnknown = -1,
    SAVServiceAVIOTypeOutput,
    SAVServiceAVIOTypeInput,
    SAVServiceAVIOTypeInternal
};

@class SAVService;

@interface SAVServiceGroup : NSObject

/**
 *  A unique identifier for the group, generally component-logicalComponent-serviceID
 */
@property NSString *identifier;

/**
 *  An alias that represents the full service group.
 */
@property (readonly, nonatomic) NSString *alias;

/**
 *  A generic service ID that represents the group (generally the service ID, without the AUDIO suffix)
 */
@property (nonatomic) NSString *serviceId;

@property (nonatomic, readonly) NSString *displayName;

@property (nonatomic, readonly) NSString *iconName;

@property (nonatomic, readonly) NSArray *zones;

@property (nonatomic, readonly) NSString *stateScope;

@property (nonatomic, readonly) NSArray *services;

@property (nonatomic, readonly) NSArray *activeServices;

@property (nonatomic, readonly) SAVService *wildCardedService;

/**
 *  Lists the supported output types for the group. Either AV, A, or AV + A
 */
@property (readonly, nonatomic) SAVServiceOutputType outputTypes;

/**
 *  The possible output type for each room.
 */
@property (readonly, nonatomic) NSDictionary *outputTypeByRoom;

/**
 *  Returns the audio service, with a wild carded zone and variant ID.
 */
@property (readonly, nonatomic) SAVService *audioService;

/**
 *  Returns the AV service, with a wild carded zone and variant ID.
 */
@property (readonly, nonatomic) SAVService *avService;

/**
 *  An array of audio variant Ids for each room.
 */
@property (readonly, nonatomic) NSDictionary *audioVariantIdsByRoom;

/**
 *  An array of video variant Ids for each room.
 */
@property (readonly, nonatomic) NSDictionary *avVariantIdsByRoom;

/**
 *  Request a fully qualified audio service given a room and variant.
 *
 *  @param room      A room.
 *  @param variantId A variant ID.
 *
 *  @return Fully qualified service object.
 */
- (SAVService *)audioServiceForRoom:(NSString *)room andVariantId:(NSString *)variantId;

/**
 *  Request a fully qualified av service given a room and variant.
 *
 *  @param room      A room.
 *  @param variantId A variant ID.
 *
 *  @return Fully qualified service object.
 */
- (SAVService *)avServiceForRoom:(NSString *)room andVariantId:(NSString *)variantId;


/**
 *  The list of all fully qualified services within a room.
 *
 *  @param room The room.
 *
 *  @return a list of services
 */
- (NSArray *)servicesForRoom:(NSString *)room;

/**
 *  The list of av fully qualified services within a room.
 *
 *  @param room The room.
 *
 *  @return a list of services
 */
- (NSArray *)avServicesForRoom:(NSString *)room;

/**
 *  The list of audio fully qualified services within a room.
 *
 *  @param room The room.
 *
 *  @return a list of services
 */
- (NSArray *)audioServicesForRoom:(NSString *)room;

/**
 *  Add a service to the group.
 *
 *  @param service The service.
 */
- (void)addService:(SAVService *)service;

- (void)removeService:(SAVService *)service;

+ (NSString *)genericServiceIdForServiceId:(NSString *)serviceId;

- (BOOL)isEqualToServiceGroup:(SAVServiceGroup *)service;

- (BOOL)matchesWildcardedService:(SAVService *)service;

- (BOOL)partiallyMatchesService:(SAVService *)service;

@end
