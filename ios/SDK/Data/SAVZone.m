//
//  SAVZone.m
//  SavantControl
//
//  Created by Ian Mortimer on 12/3/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

#import "SAVZone.h"

@implementation SAVZone

- (id)copyWithZone:(NSZone *)zone
{
    SAVZone *copy = [[[self class] alloc] init];
    
    copy.zoneId = [self.zoneId copyWithZone:zone];
    copy.zoneName = [self.zoneName copyWithZone:zone];
    copy.zoneType = [self.zoneType copyWithZone:zone];
    
    return copy;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:[SAVZone class]])
    {
        return NO;
    }
    
    return [self isEqualToZone:(SAVZone *)object];
}

- (BOOL)isEqualToZone:(SAVZone *)zone
{
    if (!zone)
    {
        return NO;
    }
    
    BOOL haveEqualZoneIDs = (!self.zoneId && !zone.zoneId) || [self.zoneId isEqualToString:zone.zoneId];
    BOOL haveEqualZoneNames = (!self.zoneName && !zone.zoneName) || [self.zoneName isEqualToString:zone.zoneName];
    
    return haveEqualZoneIDs && haveEqualZoneNames;
}

- (NSUInteger)hash
{
    return [self.zoneId hash] ^ [self.zoneName hash] ^ [self.zoneType hash];
}

@end
