//
//  SAVServiceRequest.m
//  SavantControl
//
//  Created by Ian Mortimer on 12/6/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

#import "SAVServiceRequest.h"
#import "SAVService.h"

@implementation SAVServiceRequest

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.zoneName = dict[SAVMESSAGE_ZONE_KEY];
        self.component = dict[SAVMESSAGE_COMPONENT_KEY];
        self.logicalComponent = dict[SAVMESSAGE_LOGICAL_COMPONENT_KEY];
        self.variantId = dict[SAVMESSAGE_VARIANT_ID_KEY];
        self.serviceId = dict[SAVMESSAGE_SERVICE_TYPE_KEY];
        self.request = dict[SAVMESSAGE_REQUEST_KEY];
        self.requestArguments = dict[SAVMESSAGE_REQUEST_ARGS_KEY];
        
    }
    return self;
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.zoneName = service.zoneName;
        self.component = service.component;
        self.logicalComponent = service.logicalComponent;
        self.variantId = service.variantId;
        self.serviceId = service.serviceId;
    }
    return self;
}

- (void)setService:(SAVService *)service
{
    if (service.zoneName)
        self.zoneName = service.zoneName;
    if (service.component)
        self.component = service.component;
    if (service.logicalComponent)
        self.logicalComponent = service.logicalComponent;
    if (service.variantId)
        self.variantId = service.variantId;
    if (service.serviceId)
        self.serviceId = service.serviceId;
}

- (NSString *)command
{
    return SAVMESSAGE_SERVICE_REQUEST_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.zoneName)
        dict[SAVMESSAGE_ZONE_KEY] = self.zoneName;
    if (self.component)
        dict[SAVMESSAGE_COMPONENT_KEY] = self.component;
    if (self.logicalComponent)
        dict[SAVMESSAGE_LOGICAL_COMPONENT_KEY] = self.logicalComponent;
    if (self.variantId)
        dict[SAVMESSAGE_VARIANT_ID_KEY] = self.variantId;
    if (self.serviceId)
        dict[SAVMESSAGE_SERVICE_TYPE_KEY] = self.serviceId;
    if (self.request)
        dict[SAVMESSAGE_REQUEST_KEY] = self.request;
    if (self.requestArguments)
        dict[SAVMESSAGE_REQUEST_ARGS_KEY] = self.requestArguments;
    
    return [NSDictionary dictionaryWithDictionary: dict];
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVServiceRequest *copy = [[[self class] alloc] init];
    
    copy.zoneName = [self.zoneName copyWithZone:zone];
    copy.component = [self.component copyWithZone:zone];
    copy.logicalComponent = [self.logicalComponent copyWithZone:zone];
    copy.variantId = [self.variantId copyWithZone:zone];
    copy.serviceId = [self.serviceId copyWithZone:zone];
    copy.request = [self.request copyWithZone:zone];
    copy.requestArguments = [self.requestArguments copyWithZone:zone];

    return copy;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:[SAVServiceRequest class]])
    {
        return NO;
    }
    
    return [self isEqualToRequest:(SAVServiceRequest *)object];
}

- (BOOL)isEqualToRequest:(SAVServiceRequest *)request
{
    if (!request)
    {
        return NO;
    }
    
    BOOL haveEqualZoneNames = (!self.zoneName && !request.zoneName) || [self.zoneName isEqualToString:request.zoneName];
    BOOL haveEqualComponents = (!self.component && !request.component) || [self.component isEqualToString:request.component];
    BOOL haveEqualLogicalComponents = (!self.logicalComponent && !request.logicalComponent) || [self.logicalComponent isEqualToString:request.logicalComponent];
    BOOL haveEqualVariantIDs = (!self.variantId && !request.variantId) || [self.variantId isEqualToString:request.variantId];
    BOOL haveEqualServiceIDs = (!self.serviceId && !request.serviceId) || [self.serviceId isEqualToString:request.serviceId];
    BOOL haveEqualRequests = (!self.request && !request.request) || [self.request isEqualToString:request.request];
    BOOL haveEqualRequestArguments = (!self.requestArguments && !request.requestArguments) || [self.requestArguments isEqualToDictionary:request.requestArguments];
    
    return haveEqualZoneNames && haveEqualComponents && haveEqualLogicalComponents && haveEqualVariantIDs && haveEqualServiceIDs && haveEqualRequests && haveEqualRequestArguments;
}

- (NSUInteger)hash
{
    return [self.zoneName hash] ^ [self.component hash] ^ [self.logicalComponent hash] ^ [self.variantId hash] ^ [self.serviceId hash] ^ [self.request hash] ^ [self.requestArguments hash];
}

- (NSString *)uri
{
    return [self serviceURI];
}

@end
