//
//  NSArray+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSArray+SAVExtensions.h"

@implementation NSArray (SAVExtensions)

#pragma mark - Mapping

- (NSArray *)arrayByMappingBlock:(SAVArrayMappingBlock)block
{
    return [self arrayByMappingIndexBlock:^id(id object, NSUInteger idx, BOOL *stop) {
        return block(object);
    }];
}

- (NSArray *)arrayByMappingIndexBlock:(SAVArrayMappingWithIdxBlock)block
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];

    [self enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {

        id newObject = block(object, index, stop);

        if (newObject)
        {
            [array addObject:newObject];
        }

    }];

    return [array copy];
}

#pragma mark - Filtering

- (NSArray *)filteredArrayUsingBlock:(SAVArrayFilteringBlock)block
{
    return [self objectsAtIndexes:[self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }]];
}

- (id)secondToLastObject
{
    id object = nil;

    if ([self count] >= 2)
    {
        object = self[[self count] - 2];
    }

    return object;
}

#pragma mark - Creation

+ (instancetype)arrayOfLength:(NSUInteger)length withObject:(id)object
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];

    for (NSUInteger i = 0; i < length; i++)
    {
        [array addObject:object];
    }

    return [array copy];
}

- (instancetype)arrayByInterposingItem:(id)item
{
    return [self arrayByInterposingItemWithBlock:^id {
        return item;
    }];
}

- (instancetype)arrayByInterposingItemWithBlock:(SAVArrayInterposeBlock)block
{
    NSUInteger count = [self count];

    if (!count || count == 1)
    {
        return [self copy];
    }
    else
    {
        NSMutableArray *array = [NSMutableArray array];
        id lastObject = [self lastObject];

        for (id object in self)
        {
            [array addObject:object];

            if (object != lastObject)
            {
                [array addObject:block()];
            }
        }
        
        return [array copy];
    }
}

@end
