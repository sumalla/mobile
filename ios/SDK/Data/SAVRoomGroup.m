//
//  SAVRoomGroup.m
//  SavantControl
//
//  Created by Ian Mortimer on 12/4/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

#import "SAVRoomGroup.h"

@implementation SAVRoomGroup

- (id)copyWithZone:(NSZone *)zone
{
    SAVRoomGroup *copy = [[[self class] alloc] init];
    
    copy.groupId = [self.groupId copyWithZone:zone];
    copy.groupAlias = [self.groupAlias copyWithZone:zone];
    
    return copy;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:[SAVRoomGroup class]])
    {
        return NO;
    }
    
    return [self isEqualToRoomGroup:(SAVRoomGroup *)object];
}

- (BOOL)isEqualToRoomGroup:(SAVRoomGroup *)roomGroup
{
    if (!roomGroup)
    {
        return NO;
    }
    
    BOOL haveEqualGroupIds = (!self.groupId && !roomGroup.groupId) || [self.groupId isEqualToString:roomGroup.groupId];
    BOOL haveEqualGroupAlias = (!self.groupAlias && !roomGroup.groupAlias) || [self.groupAlias isEqualToString:roomGroup.groupAlias];
    
    return haveEqualGroupIds && haveEqualGroupAlias;
}

- (NSUInteger)hash
{
    return [self.groupId hash] ^ [self.groupAlias hash];
}

@end
