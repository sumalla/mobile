//
//  SAVRoom.m
//  SavantControl
//
//  Created by Ian Mortimer on 12/3/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

#import "SAVRoom.h"
#import "SAVRoomGroup.h"

@implementation SAVRoom

#pragma mark - Initializer methods

- (instancetype)init
{
    self = [super init];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVRoom *copy = [[[self class] alloc] init];
    copy.roomId = [self.roomId copyWithZone:zone];
    copy.group = [self.group copyWithZone:zone];
    return copy;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:[SAVRoom class]])
    {
        return NO;
    }
    
    return [self isEqualToRoom:(SAVRoom *)object];
}

- (BOOL)isEqualToRoom:(SAVRoom *)room
{
    if (!room)
    {
        return NO;
    }
    
    return (!self.roomId && !room.roomId) || [self.roomId isEqualToString:room.roomId];
}

- (NSUInteger)hash
{
    return [self.roomId hash];
}

@end
