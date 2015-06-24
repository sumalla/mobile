//
//  SAVLocalUser.m
//  SavantControl
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVLocalUser.h"

@implementation SAVLocalUser

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self)
    {
        self.accountName = dictionary[@"user"];
        self.requiresAuthentication = [dictionary[@"authRequired"] boolValue];
    }

    return self;
}

#pragma mark - NSCopying methods

- (instancetype)copyWithZone:(NSZone *)zone
{
    SAVLocalUser *user = [super copyWithZone:zone];
    user.accountName = self.accountName;
    user.requiresAuthentication = self.requiresAuthentication;
    return user;
}

@end
