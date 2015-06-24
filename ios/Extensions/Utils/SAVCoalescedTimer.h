//
//  SAVCoalescedTimer.h
//  SavantControl
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

/**
 *  Use this class to coalesce work into one run loop event.
 *
 *  You can add keyed and unkeyed work. Use keyed work if there is potential that you
 *  may receive two updates for something that only want to perform once, or if you may 
 *  want to cancel that work. The order that work is performed in is undefined.
 */
@interface SAVCoalescedTimer : NSObject

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval;

/**
 *  The interval to wait for scheduled work.
 */
@property (nonatomic) NSTimeInterval timeInverval;

/**
 *  Add unkeyed work to the queue.
 *
 *  @param work A unit of work to perform when the timer fires.
 */
- (void)addWork:(dispatch_block_t)work;

/**
 *  Add keyed work to the queue. If work is already scheduled for the given key, it will be replaced with the new work.
 *
 *  @param key  A key for the work.
 *  @param work A unit of work to perform when the timer fires.
 */
- (void)addWorkWithKey:(NSString *)key work:(dispatch_block_t)work;

/**
 *  Remove any work scheduled for the given key.
 *
 *  @param key A key for the work.
 */
- (void)removeWorkWithKey:(NSString *)key;

/**
 *  Cancel all currently scheduled work.
 */
- (void)invalidate;

@end
