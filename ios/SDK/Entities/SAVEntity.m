//
//  SAVEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVEntity.h"
#import <SAVService.h>
#import <SAVServiceRequest.h>

@implementation SAVEntity

- (SAVEntity *)initWithRoomName:(NSString *)room zoneName:(NSString *)zone service:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.roomName = room;
        self.zoneName = zone;
        self.service = service;
        self.type = SAVEntityType_Unknown;
    }
    return self;
}

+ (SAVEntity *)entityFromService:(SAVService *)service
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (SAVEntityEvent)eventForCommand:(NSString *)command
{
    return SAVEntityEvent_Unknown;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (SAVEntityClass)entityClassForService:(SAVService *)service
{
    SAVEntityClass entityClass = SAVEntityClass_Unknown;

    if ([service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
    {
        entityClass = SAVEntityClass_HVAC;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_POOLANDSPA"])
    {
        entityClass = SAVEntityClass_Pool;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        entityClass = SAVEntityClass_Lighting;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
    {
        entityClass = SAVEntityClass_Shades;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_SECURITYSYSTEM"] ||
             [service.serviceId isEqualToString:@"SVC_ENV_USERLOGIN_SECURITYSYSTEM"])
    {
        entityClass = SAVEntityClass_Security;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_SECURITYCAMERA"])
    {
        entityClass = SAVEntityClass_Cameras;
    }
    else if ([service.serviceId isEqualToString:@"SVC_ENV_POOLANDSPA"])
    {
        entityClass = SAVEntityClass_Pool;
    }
    return entityClass;
}

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    return SAVEntityType_Unknown;
}

- (NSString *)stateFromType:(SAVEntityState)type
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (SAVEntityState)typeFromState:(NSString *)state
{
    return SAVEntityState_Unknown;
}

- (NSString *)nameFromState:(NSString *)state
{
    NSString *name = @"";

    if (state)
    {
        NSArray *parts = [state componentsSeparatedByString:@"."];
        if ([parts count])
        {
            NSString *last = [parts lastObject];
            NSArray *nameParts = [last componentsSeparatedByString:@"_"];
            if ([nameParts count])
            {
                name = [nameParts firstObject];
            }
        }
    }

    return name;
}

- (NSArray *)addressesFromState:(NSString *)state
{
    NSArray *addresses = nil;

    if (state)
    {
        NSArray *parts = [state componentsSeparatedByString:@"."];
        if ([parts count])
        {
            NSString *last = [parts lastObject];
            NSArray *nameParts = [last componentsSeparatedByString:@"_"];
            if ([nameParts count])
            {
                NSString *addressString = [nameParts lastObject];
                addresses = [addressString componentsSeparatedByString:@"-"];
            }
        }
    }

    return addresses;
}

- (SAVServiceRequest *)baseRequest
{
    SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:self.service];
    request.requestArguments = [self createAddressArguments];

    return request;
}

- (NSDictionary *)createAddressArguments
{
    NSMutableDictionary *addressArgs = [[NSMutableDictionary alloc] init];
    NSInteger index = 0;
    // --------------------------------------------------
    // Add each address to the arguments.
    // --------------------------------------------------
    for (NSString *currentAddr in self.addresses)
    {
        if ([currentAddr length])
        {
            NSString *key = self.addressKeyPrefix;
            SAVEntityAddressScheme scheme = self.addressScheme;
			NSInteger oneRelative = index + 1;
			
            switch (scheme)
            {
                case (SAVEntityAddressScheme_ZeroRelative):
                    key = [key stringByAppendingFormat:@"%ld", (long)index];
                    break;
                case (SAVEntityAddressScheme_OneRelative):
                    key = [key stringByAppendingFormat:@"%ld", (long)oneRelative];
                    break;
                case (SAVEntityAddressScheme_NoInitial):
                    if (oneRelative != 1)
                    {
                        key = [key stringByAppendingFormat:@"%ld", (long)oneRelative];
                    }
                    break;
            }

            // --------------------------------------------------
            // Get the current classes key prefix, and append the
            // key calculated based off the classes scheme
            // --------------------------------------------------
            addressArgs[key] = currentAddr;
            index++;
        }
    }

    return addressArgs;
}

- (NSArray *)states
{
    return nil;
}

- (NSString *)stateSuffix
{
    NSString *suffix = @"";
    for (NSString *currentAddr in self.addresses)
    {
        suffix = [suffix stringByAppendingFormat:@"_%@", currentAddr];
    }
    return suffix;
}

- (NSString *)stateScope
{
    NSString *stateScope = nil;
    if (self.service)
    {
        if (self.service.component && self.service.logicalComponent)
        {
            stateScope = [NSString stringWithFormat:@"%@.%@.", self.service.component, self.service.logicalComponent];
        }
    }

    return stateScope;
}

- (NSString *)stateFromStateName:(NSString *)stateName
{
    return [NSString stringWithFormat:@"%@%@%@", self.stateScope, stateName, self.stateSuffix];
}

- (NSString *)addressKeyPrefix
{
    return @"Address";
}

- (SAVEntityAddressScheme)addressScheme
{
    return SAVEntityAddressScheme_OneRelative;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:[SAVEntity class]])
    {
        return NO;
    }

    return [self isEqualToEntity:(SAVEntity *)object];
}

- (BOOL)isEqualToEntity:(SAVEntity *)entity
{
    if (!entity)
    {
        return NO;
    }

    BOOL haveEqualZoneNames  = (!self.zoneName && !entity.zoneName) || [self.zoneName isEqualToString:entity.zoneName];
    BOOL haveEqualRoomNames  = (!self.roomName && !entity.roomName) || [self.roomName isEqualToString:entity.roomName];
    BOOL haveEqualServices   = (!self.service && !entity.service) || [self.service isEqual:entity.service];
    BOOL haveEqualTypes      = (self.type == entity.type);
    BOOL haveEqualAddresses  = (!self.addresses && !entity.addresses) || [self.addresses isEqual:entity.addresses];
    BOOL haveEqualIdentifier = (self.identifier == entity.identifier);
    BOOL haveEqualLabels     = (!self.label && !entity.label) || [self.label isEqualToString:entity.label];

    return haveEqualZoneNames && haveEqualRoomNames && haveEqualServices && haveEqualTypes && haveEqualAddresses && haveEqualIdentifier && haveEqualLabels;
}

- (NSUInteger)hash
{
    return [self.zoneName hash] ^ [self.roomName hash] ^ [self.service hash] ^ [self.addresses hash] ^ [self.label hash];
}

@end
