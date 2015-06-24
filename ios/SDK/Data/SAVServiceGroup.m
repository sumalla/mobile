
//
//  SAVServiceGroup.m
//  SavantControl
//
//  Created by Nathan Trapp on 10/9/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVServiceGroup.h"
#import "SAVService.h"
#import "SAVMutableService.h"
#import "SAVControl.h"
#import "rpmSharedLogger.h"
#import "Savant.h"

@interface SAVServiceGroup () <NSCopying>

@property (nonatomic) SAVServiceOutputType outputTypes;
@property (nonatomic) SAVService *audioService;
@property (nonatomic) SAVService *avService;
@property (nonatomic) SAVService *envService;
@property (nonatomic) NSString *alias;

@property (nonatomic) NSMutableDictionary *internalAudioVariantIdsByRoom;
@property (nonatomic) NSMutableDictionary *internalAVVariantIdsByRoom;
@property (nonatomic) NSMutableDictionary *internalOutputTypeByRoom;
@property (nonatomic) NSMutableDictionary *serviceStringToService;
@property (nonatomic) NSMutableArray *internalServices;
@property (nonatomic) NSMutableSet *internalZones;

@property (nonatomic) SAVServiceAVIOType avioType;

@end

@implementation SAVServiceGroup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.internalServices = [NSMutableArray array];
        self.internalAudioVariantIdsByRoom = [NSMutableDictionary dictionary];
        self.internalAVVariantIdsByRoom = [NSMutableDictionary dictionary];
        self.internalOutputTypeByRoom = [NSMutableDictionary dictionary];
        self.serviceStringToService = [NSMutableDictionary dictionary];
        self.internalZones = [NSMutableSet set];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SAVServiceGroup *copy = [[SAVServiceGroup alloc] init];
    
    for (SAVService *service in self.services)
    {
        [copy addService:service];
    }
    
    return copy;
}

- (SAVService *)audioServiceForRoom:(NSString *)room andVariantId:(NSString *)variantId
{
    SAVService *service = nil;

    if ([self.internalAudioVariantIdsByRoom[room] containsObject:variantId])
    {
        service = [[SAVService alloc] initWithZone:room
                                         component:nil
                                  logicalComponent:nil
                                         variantId:variantId
                                         serviceId:nil
                                             alias:nil
                                      serviceAlias:nil
                                       connectorId:nil
                                      capabilities:nil
                                          avioType:SAVServiceAVIOTypeUnknown
                                        outputType:SAVServiceOutputTypeAudio
                                    discreteVolume:NO
                                            hidden:NO];

        @synchronized (self.internalServices)
        {
            service = [[SAVService services:self.internalServices filteredByService:service] lastObject];
        }
    }

    return service;
}

- (SAVService *)avServiceForRoom:(NSString *)room andVariantId:(NSString *)variantId
{
    SAVService *service = nil;

    if ([self.internalAVVariantIdsByRoom[room] containsObject:variantId])
    {
        service = [[SAVService alloc] initWithZone:room
                                         component:nil
                                  logicalComponent:nil
                                         variantId:variantId
                                         serviceId:nil
                                             alias:nil
                                      serviceAlias:nil
                                       connectorId:nil
                                      capabilities:nil
                                          avioType:SAVServiceAVIOTypeUnknown
                                        outputType:SAVServiceOutputTypeAudioVideo
                                    discreteVolume:NO
                                            hidden:NO];

        @synchronized (self.internalServices)
        {
            service = [[SAVService services:self.internalServices filteredByService:service] lastObject];
        }
    }

    return service;
}

- (NSArray *)servicesForRoom:(NSString *)room
{
    NSMutableArray *services = [NSMutableArray array];

    [services addObjectsFromArray:[self avServicesForRoom:room]];
    [services addObjectsFromArray:[self audioServicesForRoom:room]];

    return [services copy];
}

- (NSArray *)avServicesForRoom:(NSString *)room
{
    NSMutableSet *services = [NSMutableSet set];

    if (![self audioOnlyService])
    {
        SAVService *service = [[SAVService alloc] initWithZone:room
                                                     component:nil
                                              logicalComponent:nil
                                                     variantId:nil
                                                     serviceId:self.serviceId];

        @synchronized (self.internalServices)
        {
            [services addObjectsFromArray:[SAVService services:self.internalServices filteredByService:service]];
        }
    }

    return [services allObjects];
}

- (NSArray *)audioServicesForRoom:(NSString *)room
{
    NSMutableSet *services = [NSMutableSet set];

    SAVService *service = [[SAVService alloc] initWithZone:room
                                                 component:nil
                                          logicalComponent:nil
                                                 variantId:nil
                                                 serviceId:[SAVServiceGroup audioServiceForGenericService:self.serviceId]];

    @synchronized (self.internalServices)
    {
        [services addObjectsFromArray:[SAVService services:self.internalServices filteredByService:service]];
    }

    return [services allObjects];
}

- (void)removeService:(SAVService *)service
{
    @synchronized (self.internalServices)
    {
        if ([self.internalServices containsObject:service])
        {
            [self.internalServices removeObject:service];
            [self.internalZones removeObject:service.zoneName];
            [self.serviceStringToService removeObjectForKey:service.serviceString];

            if (service.zoneName && service.variantId && service.serviceId)
            {
                NSString *genericId = [SAVServiceGroup genericServiceIdForServiceId:service.serviceId];

                if ([service.serviceId isEqualToString:genericId] &&
                    ![self audioOnlyService])
                {
                    [self.avVariantIdsByRoom[service.zoneName] removeObject:service.variantId];
                }
                else
                {
                    [self.audioVariantIdsByRoom[service.zoneName] removeObject:service.variantId];
                }
            }

            if (![self.internalServices count])
            {
                self.identifier = nil;
                self.serviceId = nil;
                self.alias = nil;
                self.envService = nil;
                self.avService = nil;
                self.audioService = nil;
            }
        }
    }
}

- (void)addService:(SAVService *)service
{
    NSParameterAssert(service);

    @synchronized (self.internalServices)
    {
        if (!self.serviceStringToService[service.serviceString])
        {
            //-------------------------------------------------------------------
            // Don't verify logical component if service is SVC_GEN_GENERIC, it doesn't have one
            //-------------------------------------------------------------------
            BOOL hasLogicalComponent = [service.serviceId isEqualToString:@"SVC_GEN_GENERIC"] ? YES : [service.logicalComponent length];

            //-------------------------------------------------------------------
            // This is a fully qualified service, or an ENV service
            //-------------------------------------------------------------------
            if (([service.zoneName length] && [service.component length] && [service.variantId length] && [service.serviceId length] && hasLogicalComponent) || [service.serviceId hasPrefix:@"SVC_ENV_"])
            {
                NSString *genericId = [[self class] genericServiceIdForServiceId:service.serviceId];

                if (!self.serviceId)
                {
                    self.serviceId = [[self class] genericServiceIdForServiceId:service.serviceId];
                }

                if (!self.identifier)
                {
                    self.identifier = service.identifier;
                }

                if (!self.alias)
                {
                    self.alias = service.serviceAlias;
                }

                if ([genericId isEqualToString:self.serviceId])
                {
                    if ([genericId hasPrefix:@"SVC_ENV"])
                    {
                        self.envService = [[SAVService alloc] initWithZone:nil
                                                                 component:service.component
                                                          logicalComponent:service.logicalComponent
                                                                 variantId:nil
                                                                 serviceId:service.serviceId
                                                                     alias:service.alias
                                                              serviceAlias:service.serviceAlias
                                                               connectorId:service.connectorId
                                                              capabilities:service.capabilities
                                                                  avioType:service.avioType
                                                                outputType:service.outputType
                                                            discreteVolume:service.discreteVolume
                                                                    hidden:service.hidden];
                    }
                    else
                    {
                        NSMutableDictionary *storage = nil;

                        if ([service.serviceId isEqualToString:genericId] &&
                            ![self audioOnlyService])
                        {
                            storage = self.internalAVVariantIdsByRoom;

                            if (!self.avService)
                            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
                                switch (service.avioType)
                                {
                                    case SAVServiceAVIOTypeInput:
                                    case SAVServiceAVIOTypeInternal:
                                        self.avService = [[SAVService alloc] initWithZone:nil
                                                                                component:service.component
                                                                         logicalComponent:nil
                                                                                variantId:nil
                                                                                serviceId:service.serviceId
                                                                                    alias:service.alias
                                                                             serviceAlias:service.serviceAlias
                                                                              connectorId:service.connectorId
                                                                             capabilities:service.capabilities
                                                                                 avioType:service.avioType
                                                                               outputType:service.outputType
                                                                           discreteVolume:service.discreteVolume
                                                                                   hidden:service.hidden];

                                        break;
                                    case SAVServiceAVIOTypeOutput:
                                    case SAVServiceAVIOTypeUnknown:
                                    default:
                                        self.avService = [[SAVService alloc] initWithZone:nil
                                                                                component:service.component
                                                                         logicalComponent:service.logicalComponent
                                                                                variantId:nil
                                                                                serviceId:service.serviceId
                                                                                    alias:service.alias
                                                                             serviceAlias:service.serviceAlias
                                                                              connectorId:service.connectorId
                                                                             capabilities:service.capabilities
                                                                                 avioType:service.avioType
                                                                               outputType:service.outputType
                                                                           discreteVolume:service.discreteVolume
                                                                                   hidden:service.hidden];

                                        break;
                                }
                            }
#pragma clang diagnostic pop
                        }
                        else
                        {
                            storage = self.internalAudioVariantIdsByRoom;

                            if (!self.audioService)
                            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
                                switch (service.avioType)
                                {
                                    case SAVServiceAVIOTypeInput:
                                    case SAVServiceAVIOTypeInternal:
                                        self.audioService = [[SAVService alloc] initWithZone:nil
                                                                                   component:service.component
                                                                            logicalComponent:nil
                                                                                   variantId:nil
                                                                                   serviceId:service.serviceId
                                                                                       alias:service.alias
                                                                                serviceAlias:service.serviceAlias
                                                                                 connectorId:service.connectorId
                                                                                capabilities:service.capabilities
                                                                                    avioType:service.avioType
                                                                                  outputType:service.outputType
                                                                              discreteVolume:service.discreteVolume
                                                                                      hidden:service.hidden];

                                        break;
                                    case SAVServiceAVIOTypeOutput:
                                    case SAVServiceAVIOTypeUnknown:
                                    default:
                                        self.audioService = [[SAVService alloc] initWithZone:nil
                                                                                   component:service.component
                                                                            logicalComponent:service.logicalComponent
                                                                                   variantId:nil
                                                                                   serviceId:service.serviceId
                                                                                       alias:service.alias
                                                                                serviceAlias:service.serviceAlias
                                                                                 connectorId:service.connectorId
                                                                                capabilities:service.capabilities
                                                                                    avioType:service.avioType
                                                                                  outputType:service.outputType
                                                                              discreteVolume:service.discreteVolume
                                                                                      hidden:service.hidden];

                                        break;
                                }
#pragma clang diagnostic pop
                            }
                        }

                        NSMutableArray *variantList = storage[service.zoneName];
                        if (!variantList)
                        {
                            variantList = [NSMutableArray array];
                            storage[service.zoneName] = variantList;
                        }

                        if (![variantList containsObject:service.variantId])
                        {
                            [variantList addObject:service.variantId];
                        }

                        self.outputTypes |= service.outputType;

                        SAVServiceOutputType roomType = [self.internalOutputTypeByRoom[service.zoneName] integerValue] | service.outputType;
                        self.internalOutputTypeByRoom[service.zoneName] = @(roomType);

                        [self.internalZones addObject:service.zoneName];
                    }

                    self.serviceStringToService[service.serviceString] = service;
                    [self.internalServices addObject:service];
                }
                else
                {
                    RPMLogErr(@"Attempted to add a service to the wrong group: %@, %@", genericId, self.serviceId);
                }
            }
            else
            {
                //-------------------------------------------------------------------
                // If not a fully qualified service, fetch all the matching fully
                // qualified services and add them to the group
                //-------------------------------------------------------------------
                SAVMutableService *filterService = [service mutableCopy];
                NSString *serviceId = filterService.serviceId;
                if ([serviceId isEqualToString:[SAVServiceGroup genericServiceIdForServiceId:serviceId]])
                {
                    serviceId = [SAVServiceGroup audioServiceForGenericService:serviceId];
                }
                else
                {
                    serviceId = [SAVServiceGroup genericServiceIdForServiceId:serviceId];
                }
                
                NSArray *services = [[Savant data] servicesFilteredByService:filterService];
                filterService.serviceId = serviceId;
                
                services = [services arrayByAddingObjectsFromArray:[[Savant data] servicesFilteredByService:filterService]];
                
                for (SAVService *s in services)
                {
                    [self addService:s];
                }
            }
        }
        else
        {
            RPMLogErr(@"Service group can only contain unique services, attempted to add duplicate %@", service.serviceString);
        }
    }
}

+ (NSString *)audioServiceForGenericService:(NSString *)serviceId
{
    if (![serviceId hasSuffix:@"AUDIO"])
    {
        serviceId = [serviceId stringByAppendingString:@"AUDIO"];
    }
    return serviceId;
}

+ (NSString *)genericServiceIdForServiceId:(NSString *)serviceId
{
    NSString *genericId = serviceId;
    if ([serviceId hasSuffix:@"AUDIO"] &&
        !([serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"] || [serviceId isEqualToString:@"SVC_AV_GENERALAUDIO"]))
    {
        genericId = [genericId stringByReplacingCharactersInRange:NSMakeRange([genericId length] - 5, 5) withString:@""];
    }

    return genericId;
}

#pragma mark - Getters

- (NSDictionary *)audioVariantIdsByRoom
{
    return [self.internalAudioVariantIdsByRoom copy];
}

- (NSDictionary *)avVariantIdsByRoom
{
    return [self.internalAVVariantIdsByRoom copy];
}

- (NSDictionary *)outputTypeByRoom
{
    return [self.internalOutputTypeByRoom copy];
}

- (NSString *)displayName
{
    return [SAVService displayNameForServiceID:self.serviceId];
}

- (NSString *)iconName
{
    return [SAVService iconNameForServiceID:self.serviceId];
}

- (NSArray *)zones
{
    return [self.internalZones allObjects];
}

- (NSString *)stateScope
{
    NSString *stateScope = nil;
    SAVService *service = [self.activeServices firstObject] ?: [self.services firstObject];

    if ([service.logicalComponent length] && [service.component length])
    {
        stateScope = [NSString stringWithFormat:@"%@.%@", service.component, service.logicalComponent];
    }

    return stateScope;
}

- (NSArray *)services
{
    @synchronized (self.internalServices)
    {
        return [self.internalServices copy];
    }
}

- (NSArray *)activeServices
{
    NSMutableSet *services = [NSMutableSet setWithArray:self.services];
    [services intersectSet:[NSSet setWithArray:[Savant states].activeServices]];

    return [services allObjects];
}

- (SAVService *)wildCardedService
{
    return self.envService ? : (self.avService ? : self.audioService);
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:[SAVServiceGroup class]])
    {
        return NO;
    }

    return [self isEqualToServiceGroup:(SAVServiceGroup *)object];
}

- (BOOL)isEqualToServiceGroup:(SAVServiceGroup *)service
{
    if (!service)
    {
        return NO;
    }

    return [service.identifier isEqualToString:self.identifier] && [service.zones isEqualToArray:self.zones] && [service.services isEqualToArray:self.services];
}

- (NSUInteger)hash
{
    return [self.identifier hash] ^ [self.zones hash] ^ [self.services hash];
}

- (NSString *)description
{
    return self.identifier;
}

- (BOOL)matchesWildcardedService:(SAVService *)service
{
    BOOL matches = NO;

    @synchronized (self.internalServices)
    {
        for (SAVService *s in self.internalServices)
        {
            if ([s matchesWildcardedService:service])
            {
                matches = YES;
                break;
            }
        }
    }

    return matches;
}

- (BOOL)partiallyMatchesService:(SAVService *)service
{
    BOOL matches = NO;
    
    @synchronized (self.internalServices)
    {
        for (SAVService *s in self.internalServices)
        {
            if ([s.identifier isEqualToString:service.identifier])
            {
                matches = YES;
                break;
            }
        }
    }
    
    return matches;
}

- (BOOL)audioOnlyService
{
    return [self.serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"] || [self.serviceId isEqualToString:@"SVC_AV_GENERALAUDIO"];
}

@end
