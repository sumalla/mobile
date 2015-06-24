//
//  NSSet+SAVExtensions.m
//  SavantExtensions
//
//  Created by Stephen Silber on 11/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSSet+SAVExtensions.h"

@implementation NSSet (SAVExtensions)

- (NSSet *)sav_minusSet:(NSSet *)set
{
    NSMutableSet *mSet = [self mutableCopy];
    [mSet minusSet:set];
    return [mSet copy];
}

- (NSSet *)sav_minusArray:(NSArray *)array
{
    NSMutableSet *first = [self mutableCopy];
    NSMutableSet *second = [NSMutableSet setWithArray:array];
    
    [first minusSet:second];
    
    return [first copy];
}

@end
