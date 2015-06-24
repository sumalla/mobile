//
//  NSNull+SAVExtensions.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 10/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSNull+SAVExtensions.h"

@implementation NSNull (SAVExtensions)

+ (id)nilOrIdentityFromObject:(id)object
{
    if ([object isEqual:[NSNull null]])
    {
        return nil;
    }
    else
    {
        return object;
    }
}

@end
