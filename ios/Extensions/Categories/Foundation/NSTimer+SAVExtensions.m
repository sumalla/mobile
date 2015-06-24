//
//  NSTimer+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSTimer+SAVExtensions.h"

@implementation NSTimer (SAVExtensions)

+ (NSTimer *)sav_scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo block:(dispatch_block_t)block
{
    NSParameterAssert(block);
    NSTimer *timer = [[self class] timerWithTimeInterval:ti target:self selector:@selector(sav_performBlock:) userInfo:[block copy] repeats:yesOrNo];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)sav_scheduledBlockWithDelay:(NSTimeInterval)ti block:(dispatch_block_t)block
{
    return [[self class] sav_scheduledTimerWithTimeInterval:ti repeats:NO block:block];
}

+ (void)sav_performBlock:(NSTimer *)timer
{
    dispatch_block_t block = (dispatch_block_t)[timer userInfo];
    block();
}

@end
