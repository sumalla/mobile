//
//  SAVCoalescedTimer.m
//  SavantControl
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVCoalescedTimer.h"

@interface SAVCoalescedTimer ()

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic) NSMutableArray *unkeyedWork;
@property (nonatomic) NSMutableDictionary *keyedWork;

@end

@implementation SAVCoalescedTimer

- (void)dealloc
{
    [self invalidate];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
{
    self = [super init];

    if (self)
    {
        self.unkeyedWork = [NSMutableArray array];
        self.keyedWork = [NSMutableDictionary dictionary];
        self.timeInverval = timeInterval;
    }

    return self;
}

- (instancetype)init
{
    self = [self initWithTimeInterval:0];
    return self;
}

- (void)addWork:(dispatch_block_t)work
{
    NSParameterAssert(work);
    [self.unkeyedWork addObject:work];
    [self kickTimer];
}

- (void)addWorkWithKey:(NSString *)key work:(dispatch_block_t)work
{
    NSParameterAssert(key);
    NSParameterAssert(work);
    self.keyedWork[key] = work;
    [self kickTimer];
}

- (void)removeWorkWithKey:(NSString *)key
{
    NSParameterAssert(key);
    [self.keyedWork removeObjectForKey:key];
}

- (void)kickTimer
{
    if (![self.timer isValid])
    {
        NSTimer *timer = [NSTimer timerWithTimeInterval:self.timeInverval
                                                 target:self
                                               selector:@selector(performWork:)
                                               userInfo:nil
                                                repeats:NO];

        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
}

- (void)invalidate
{
    [self.timer invalidate];
    [self clearWork];
}

#pragma mark -

- (void)performWork:(NSTimer *)timer
{
    NSArray *unkeyedWork = [self.unkeyedWork copy];
    NSDictionary *keyedWork = [self.keyedWork copy];
    [self invalidate];

    for (dispatch_block_t work in unkeyedWork)
    {
        work();
    }

    for (dispatch_block_t work in [keyedWork allValues])
    {
        work();
    }
}

- (void)clearWork
{
    [self.unkeyedWork removeAllObjects];
    [self.keyedWork removeAllObjects];
}

@end
