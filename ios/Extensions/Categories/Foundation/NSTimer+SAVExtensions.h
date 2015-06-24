//
//  NSTimer+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

@interface NSTimer (SAVExtensions)

+ (NSTimer *)sav_scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo block:(dispatch_block_t)block;

+ (NSTimer *)sav_scheduledBlockWithDelay:(NSTimeInterval)ti block:(dispatch_block_t)block;

@end
