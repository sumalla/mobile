//
//  NSArray+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
#import "SAVCollectionTypes.h"

@interface NSArray (SAVExtensions)

#pragma mark - Mapping

/**
 *  Returns a new array that is the result of performing the given block on each object in the receiving array.
 *
 *  @param block A block that will be performed with each object in the array. Return nil to act like a filter.
 *
 *  @return A new array that is the result of performing the given block on each object in the receiving array.
 */
- (NSArray *)arrayByMappingBlock:(SAVArrayMappingBlock)block;

- (NSArray *)arrayByMappingIndexBlock:(SAVArrayMappingWithIdxBlock)block;

#pragma mark - Filtering

/**
 *  Evaluates a given block against each object in the receiving array and returns an array containing the objects for which the block returns true.
 *
 *  @param block The block against which to evaluate the receiving array’s elements.
 *
 *  @return An array containing the objects in the receiving array for which block returns true.
 */
- (NSArray *)filteredArrayUsingBlock:(SAVArrayFilteringBlock)block;

/**
 *  Returns the second to last object in the array, or nil if there is only one object.
 *
 *  @return The second to last object in the array, or nil if there is only one object.
 */
- (id)secondToLastObject;

#pragma mark - Creation

+ (instancetype)arrayOfLength:(NSUInteger)length withObject:(id)object;

/**
 *  Returns the receiver with the given object interposed between each of its elements. If the receiver has 0 or 1 objects, it is returned as is.
 *
 *  @param item The object to interpose between each object of the receiver.
 *
 *  @return A new array with the given item interposed between each of the receivers elements.
 */
- (instancetype)arrayByInterposingItem:(id)item;
- (instancetype)arrayByInterposingItemWithBlock:(SAVArrayInterposeBlock)block;

@end
