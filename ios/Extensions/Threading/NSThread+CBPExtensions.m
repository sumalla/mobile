/*
 The MIT License (MIT)
 
 Copyright (c) 2014 Cameron Pulsford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "NSThread+CBPExtensions.h"

#define CBPThreadKeyLock   @"lock"
#define CBPThreadKeyThread @"thread"

@implementation NSThread (CBPExtensions)

#pragma mark - Long running thread methods

+ (NSThread *)cbp_runningThread
{
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];
    
    NSMutableDictionary *threadDict = [NSMutableDictionary dictionary];
    threadDict[CBPThreadKeyLock] = lock;
    
    [NSThread detachNewThreadSelector:@selector(cbp_runThread:)
                             toTarget:self
                           withObject:threadDict];
    
    [lock lockWhenCondition:1];
    [lock unlock];
    
    return threadDict[CBPThreadKeyThread];
}

+ (void)cbp_runThread:(NSMutableDictionary *)threadDict
{
    @autoreleasepool
    {
        NSThread *currentThread = [NSThread currentThread];
        
        threadDict[CBPThreadKeyThread] = currentThread;
        
        NSConditionLock *lock = threadDict[CBPThreadKeyLock];
        [lock lock];
        [lock unlockWithCondition:1];
        
        [currentThread performSelector:@selector(cbp_dummy) withObject:nil afterDelay:0.0];
        
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        
        while (!currentThread.isCancelled)
        {
            [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (void)cbp_dummy
{
    ;
}

- (void)cbp_stop
{
    [self cbp_performBlockSync:^{
        
        [self cancel];
        
    }];
}

#pragma mark - Block methods

- (void)cbp_performBlockSync:(dispatch_block_t)block
{
    [self cbp_doPerformBlock:block sync:YES];
}

- (void)cbp_performBlockAsync:(dispatch_block_t)block
{
    [self cbp_doPerformBlock:block sync:NO];
}

- (void)cbp_doPerformBlock:(dispatch_block_t)block
{
    block();
}

- (void)cbp_doPerformBlock:(dispatch_block_t)block sync:(BOOL)sync
{
    if ([NSThread currentThread] == self)
    {
        if (sync)
        {
            block();
        }
        else
        {
            [self performSelector:@selector(cbp_doPerformBlock:)
                       withObject:[block copy]
                       afterDelay:0.0];
        }
    }
    else
    {
        [self performSelector:@selector(cbp_doPerformBlock:)
                     onThread:self
                   withObject:[block copy]
                waitUntilDone:sync];
    }
}

@end
