//
//  NSMutableArray+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSMutableArray+SAVExtensions.h"

@implementation NSMutableArray (SAVExtensions)

- (void)filterArrayUsingBlock:(SAVArrayFilteringBlock)block
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (!block(obj))
        {
            [indexSet addIndex:idx];
        }
        
    }];
    
    [self removeObjectsAtIndexes:indexSet];
}

@end
