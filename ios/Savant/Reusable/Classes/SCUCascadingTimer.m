//
//  SCUCascadingTimer.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCascadingTimer.h"

static NSString *SCUCascadingTimerKeyDelay = @"SCUCascadingTimerKeyDelay";
static NSString *SCUCascadingTimerKeyBlock = @"SCUCascadingTimerKeyBlock";

@interface SCUCascadingTimer ()

@property (nonatomic, weak) NSTimer *currentTimer;

@property (nonatomic) NSMutableArray *delayedInvocations;

@end

@implementation SCUCascadingTimer

- (void)dealloc
{
    [self invalidate];
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.delayedInvocations = [NSMutableArray array];
    }

    return self;
}

- (void)addBlockAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block
{
    NSParameterAssert(block);

    if (self.currentTimer)
    {
        [self.delayedInvocations addObject:@{SCUCascadingTimerKeyDelay: @(delay),
                                             SCUCascadingTimerKeyBlock: [block copy]}];
    }
    else
    {
        SAVWeakSelf;

        self.currentTimer = [NSTimer sav_scheduledBlockWithDelay:delay block:^{

            //-------------------------------------------------------------------
            // Perform the current block.
            //-------------------------------------------------------------------
            block();

            //-------------------------------------------------------------------
            // Schedule the next timer on the queue.
            //-------------------------------------------------------------------
            NSDictionary *nextTimerInfo = [wSelf.delayedInvocations firstObject];

            if (nextTimerInfo)
            {
                [wSelf.delayedInvocations removeObjectAtIndex:0];
                NSTimeInterval nextDelay = [nextTimerInfo[SCUCascadingTimerKeyDelay] doubleValue];
                dispatch_block_t nextBlock = (dispatch_block_t)nextTimerInfo[SCUCascadingTimerKeyBlock];
                wSelf.currentTimer = nil;
                [wSelf addBlockAfterDelay:nextDelay block:nextBlock];
            }

        }];
    }
}

- (void)invalidate
{
    [self.currentTimer invalidate];
    [self.delayedInvocations removeAllObjects];
}

@end
