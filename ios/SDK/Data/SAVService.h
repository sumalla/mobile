//
//  SAVService.h
//  SavantControl
//
//  Created by Ian Mortimer on 12/4/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
#import "SAVServiceGroup.h"

typedef NS_ENUM(NSUInteger, SAVServiceTypeForDynamicCommandOrder)
{
    SAVServiceTypeForDynamicCommandOrderUnknown,
    SAVServiceTypeForDynamicCommandOrderTV,
    SAVServiceTypeForDynamicCommandOrderDVDMedia,
    SAVServiceTypeForDynamicCommandOrderSecurity
};

@interface SAVService : NSObject <NSCopying, NSMutableCopying>

- (nonnull instancetype)initWithZone:(nullable NSString *)zone
                           component:(nullable NSString *)component
                    logicalComponent:(nullable NSString *)logicalComponent
                           variantId:(nullable NSString *)variantId
                           serviceId:(nullable NSString *)serviceId
                               alias:(nullable NSString *)alias
                        serviceAlias:(nullable NSString *)serviceAlias
                         connectorId:(nullable NSString *)connectorId
                        capabilities:(nullable NSArray *)capabilities
                            avioType:(SAVServiceAVIOType)avioType
                          outputType:(SAVServiceOutputType)outputType
                      discreteVolume:(BOOL)discreteVolume
                              hidden:(BOOL)hidden;

- (nonnull instancetype)initWithZone:(nullable NSString *)zone
                           component:(nullable NSString *)component
                    logicalComponent:(nullable NSString *)logicalComponent
                           variantId:(nullable NSString *)variantId
                           serviceId:(nullable NSString *)serviceId;

- (nullable instancetype)initWithString:(nonnull NSString *)serviceString;

- (nullable instancetype)initWithString:(nonnull NSString *)serviceString queryService:(BOOL)query;

@property (nonatomic, readonly, nullable) NSString *zoneName;
@property (nonatomic, readonly, nullable) NSString *component;
@property (nonatomic, readonly, nullable) NSString *logicalComponent;
@property (nonatomic, readonly, nullable) NSString *variantId;
@property (nonatomic, readonly, nullable) NSString *serviceId;
@property (nonatomic, readonly, nullable) NSString *alias;
@property (nonatomic, readonly, nullable) NSString *serviceAlias;
@property (nonatomic, readonly, nullable) NSString *connectorId;
@property (nonatomic, readonly, nullable) NSArray *capabilities;
@property (nonatomic, readonly) SAVServiceAVIOType avioType;
@property (nonatomic, readonly) SAVServiceOutputType outputType;
@property (nonatomic, readonly) BOOL discreteVolume;
@property (nonatomic, readonly) BOOL hidden;

@property (nonatomic, readonly, nonnull) NSString *displayName;
@property (nonatomic, readonly, nonnull) NSString *uniquePresentableName;
@property (nonatomic, readonly, nonnull) NSString *iconName;
@property (nonatomic, readonly, nullable) NSString *identifier;
@property (nonatomic, readonly, nullable) NSArray *commands;
@property (nonatomic, readonly, nullable) NSArray *customCommands;
@property (nonatomic, readonly, nullable) NSArray *channelCommands;
@property (nonatomic, readonly, nullable) NSArray *pageCommands;
@property (nonatomic, readonly, nullable) NSArray *navigationCommands;
@property (nonatomic, readonly, nullable) NSArray *numberPadCommands;
@property (nonatomic, readonly, nullable) NSArray *dynamicCommands;
@property (nonatomic, readonly, nullable) NSArray *volumeCommands;
@property (nonatomic, readonly, nullable) NSArray *powerCommands;
@property (nonatomic, readonly, nullable) NSArray *favoriteCommands;
@property (nonatomic, readonly, nullable) NSArray *transportCommands;
@property (nonatomic, readonly, nullable) NSArray *transportGenericCommands;
@property (nonatomic, readonly, nullable) NSArray *transportBackCommands;
@property (nonatomic, readonly, nullable) NSArray *transportForwardCommands;
@property (nonatomic, readonly, nullable) NSString *serviceString;

#pragma mark - Equality

- (BOOL)isEqualToService:(nullable SAVService *)service;

/**
 *  Compares a service minus the zone and variant ID pieces.
 *
 *  @param service The service.
 *
 *  @return YES if the receiver's and service's component, logical component and service id's are equal.
 */
- (BOOL)isPartiallyEqualToService:(nullable SAVService *)service;

- (BOOL)matchesWildcardedService:(nullable SAVService *)service;

+ (BOOL)serviceID:(nonnull NSString *)serviceID matchesServiceIDs:(nonnull NSArray *)serviceIDs includeAudioVariants:(BOOL)audio;

+ (nonnull NSArray *)services:(nonnull NSArray *)services filteredByService:(nullable SAVService *)service;

+ (nonnull NSString *)displayNameForServiceID:(nullable NSString *)serviceId;

+ (SAVServiceTypeForDynamicCommandOrder)SAVServiceTypeForServiceID:(nonnull NSString *)serviceId;

+ (nonnull NSString *)iconNameForServiceID:(nullable NSString *)serviceID;

+ (SAVServiceAVIOType)avioTypeForString:(nonnull NSString *)avioType;
+ (SAVServiceOutputType)outputTypeForString:(nonnull NSString *)avType;

+ (BOOL)isLMQService:(nullable NSString *)serviceID;

@end
