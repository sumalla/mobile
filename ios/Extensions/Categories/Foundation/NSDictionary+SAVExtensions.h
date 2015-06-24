//
//  NSDictionary+SAVExtensions.h
//  SavantControl
//
//  Created by Cameron Pulsford on 6/7/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@interface NSDictionary (SAVExtensions)

- (NSArray *)sav_sortedStringKeys;

- (NSArray *)sav_valuesForSortedStringKeys;

- (NSDictionary *)sav_filteredDictionaryByMappingBlock:(BOOL (^)(id key, id value))block;

- (NSDictionary *)dictionaryByAddingObject:(id)object forKey:(id<NSCopying>)key;

@end
