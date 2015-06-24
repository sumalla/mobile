//
//  NSMutableArray+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
#import "SAVCollectionTypes.h"

@interface NSMutableArray (SAVExtensions)

/**
 *  Evaluates a given block against the array’s content and leaves only objects for which the block returns true.
 *
 *  @param block The block against which to evaluate the receiving array’s elements.
 */
- (void)filterArrayUsingBlock:(SAVArrayFilteringBlock)block;

@end
