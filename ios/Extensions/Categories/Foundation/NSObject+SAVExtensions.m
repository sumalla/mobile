//
//  SAVExtensions.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 1/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "NSObject+SAVExtensions.h"

@implementation SAVExtensions

- (instancetype)sav_asClass:(Class)asClass
{
    if ([self isKindOfClass:asClass])
    {
        return self;
    }
    else
    {
        return nil;
    }
}

@end
