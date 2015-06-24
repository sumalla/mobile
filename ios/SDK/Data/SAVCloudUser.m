//
//  SAVCloudUser.m
//  SavantControl
//
//  Created by Cameron Pulsford on 8/19/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVCloudUser.h"
#import "SavantPrivate.h"
#import "SAVControlPrivate.h"

@implementation SAVCloudUser

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self)
    {
        self.firstName = dictionary[@"firstName"];

        if ([self.firstName isEqual:[NSNull null]] || ![self.firstName length])
        {
            self.firstName = @"";
        }

        self.lastName = dictionary[@"lastName"];

        if ([self.lastName isEqual:[NSNull null]] || ![self.lastName length])
        {
            self.lastName = @"";
        }

        self.identifier = dictionary[@"id"];
        self.email = dictionary[@"email"];

        if ([self.email isEqualToString:[Savant credentials].cloudEmail])
        {
            self.currentUser = YES;
        }

        NSMutableString *name = [NSMutableString string];

        if ([self.firstName length])
        {
            [name appendString:self.firstName];

            if ([self.lastName length])
            {
                [name appendFormat:@" %@", self.lastName];
            }
        }
        else if ([self.lastName length])
        {
            [name appendString:self.lastName];
        }

        if (!([self.firstName length] || [self.lastName length]))
        {
            [name appendString:self.email];
        }

        self.name = [name copy];

        NSDictionary *permissions = dictionary[@"permissions"];
        self.canManageUsers = [permissions[@"admin"] boolValue];
        self.canManageNotifications = [permissions[@"notifications"] boolValue];
        self.hasRemoteAccess = [permissions[@"remote"] boolValue];

        NSArray *serviceBlacklist = permissions[@"serviceBlacklist"];

        if ([serviceBlacklist count])
        {
            self.serviceBlackList = [NSSet setWithArray:serviceBlacklist];
        }
        else
        {
            self.serviceBlackList = [NSSet set];
        }

        NSArray *zoneBlacklist = permissions[@"zoneBlacklist"];

        if ([zoneBlacklist count])
        {
            self.zoneBlackList = [NSSet setWithArray:zoneBlacklist];
        }
        else
        {
            self.zoneBlackList = [NSSet set];
        }
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mainDict = [NSMutableDictionary dictionary];
    [mainDict setValue:self.email forKey:@"email"];
    [mainDict setObject:self.firstName forKey:@"firstName"];
    [mainDict setObject:self.lastName forKey:@"lastName"];

    NSMutableDictionary *permissions = [NSMutableDictionary dictionary];
    permissions[@"admin"] = @(self.canManageUsers);
    permissions[@"remote"] = @(self.hasRemoteAccess);
    permissions[@"notifications"] = @(self.canManageNotifications);
    [permissions setValue:[self.zoneBlackList allObjects] forKey:@"zoneBlacklist"];
    [permissions setValue:[self.serviceBlackList allObjects] forKey:@"serviceBlacklist"];
    [mainDict setObject:[permissions copy] forKey:@"permissions"];

    return [mainDict copy];
}

#pragma mark - NSCopying methods

- (instancetype)copyWithZone:(NSZone *)zone
{
    SAVCloudUser *user = [[[self class] alloc] init];
    user.email = self.email;
    user.name = self.name;
    user.firstName = self.firstName;
    user.lastName = self.lastName;
    user.identifier = self.identifier;
    user.currentUser = self.isCurrentUser;
    user.hasRemoteAccess = self.hasRemoteAccess;
    user.canManageUsers = self.canManageUsers;
    user.canManageNotifications = self.canManageNotifications;
    user.zoneBlackList = self.zoneBlackList;
    user.serviceBlackList = self.serviceBlackList;
    return user;
}

@end
