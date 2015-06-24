//
//  SAVUser.m
//  Pods
//
//  Created by Cameron Pulsford on 8/19/14.
//
//

#import "SAVUser.h"

@implementation SAVUser

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self)
    {
        self.zoneBlackList = dictionary[@"zones"];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SAVUser *user = [[[self class] alloc] init];
    user.zoneBlackList = self.zoneBlackList;
    return user;
}

@end
