//
//  NSDictionary+SAVExtensions.m
//  SavantControl
//
//  Created by Cameron Pulsford on 6/7/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "NSDictionary+SAVExtensions.h"
#import "NSString+SAVExtensions.h"
#import "NSArray+SAVExtensions.h"

@implementation NSDictionary (SAVExtensions)

- (NSArray *)sav_sortedStringKeys
{
    return [[self allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        return [s1 compare:s2 options:NSCaseInsensitiveNumericSearch];
    }];
}

- (NSArray *)sav_valuesForSortedStringKeys
{
    return [[self sav_sortedStringKeys] arrayByMappingBlock:^id(NSString *key) {
        return self[key];
    }];
}

- (NSDictionary *)sav_filteredDictionaryByMappingBlock:(BOOL (^)(id key, id value))block
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

        if (block(key, obj))
        {
            dict[key] = obj;
        }
        
    }];

    return [dict copy];
}

- (NSDictionary *)dictionaryByAddingObject:(id)object forKey:(id<NSCopying>)key
{
    NSMutableDictionary *dictionary = [self mutableCopy];
    [dictionary setObject:object forKey:key];
    return [dictionary copy];
}

@end
