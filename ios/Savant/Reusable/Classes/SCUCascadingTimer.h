//
//  SCUCascadingTimer.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;

/**
 *  This class allows you to coordindate the queue-ing of timers and cancel them as a single unit.
 */
@interface SCUCascadingTimer : NSObject

/**
 *  Adds a new block to the queue. If no blocks are currently in the queue this block will behave as a normal NSTimer.
 *
 *  @param delay The delay before performing the block.
 *  @param block The block to perform.
 */
- (void)addBlockAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block;

- (void)invalidate;

@end
