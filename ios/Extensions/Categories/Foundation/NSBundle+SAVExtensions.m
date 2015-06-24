//
//  NSBundle+SAVExtensions.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 11/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSBundle+SAVExtensions.h"

@implementation NSBundle (SAVExtensions)

- (NSString *)sav_rootIdentifier
{
    NSString *identifier = [self bundleIdentifier];
    NSArray *identifierComponents = [identifier componentsSeparatedByString:@"."];

    if ([identifierComponents count] >= 3)
    {
        return [[identifierComponents subarrayWithRange:NSMakeRange(0, 3)] componentsJoinedByString:@"."];
    }
    else
    {
        return identifier;
    }
}

@end
