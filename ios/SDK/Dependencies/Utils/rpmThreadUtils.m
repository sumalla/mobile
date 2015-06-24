//
//  rpmThreadUtils.m
//  rpmGeneralUtils
//
//  Created by Cameron Pulsford on 5/6/13.
//
//

//##OBJCLEAN_SKIP##

#import "rpmThreadUtils.h"

#define LOCK_KEY   @"lock"
#define THREAD_KEY @"thread"

@interface rpmThreadUtils ()
+ (void)runningThread:(NSMutableDictionary *)threadDict;
@end

@implementation rpmThreadUtils

+ (NSThread *)runningThread
{
    NSMutableDictionary *threadDict = [NSMutableDictionary dictionary];
    
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];
    
    [threadDict setObject:lock forKey:LOCK_KEY];
    
    [NSThread detachNewThreadSelector:@selector(runningThread:) toTarget:self withObject:threadDict];
    
    [lock lockWhenCondition:1];
    [lock unlock];
    [lock release];
    
    return [threadDict objectForKey:THREAD_KEY];
}

+ (void)runningThread:(NSMutableDictionary *)threadDict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //-------------------------------------------------------------------
    // Get and save the current thread.
    //-------------------------------------------------------------------
    NSThread *currentThread = [NSThread currentThread];
    [threadDict setObject:currentThread forKey:THREAD_KEY];
    
    //-------------------------------------------------------------------
    // Signal that the thread has been set.
    //-------------------------------------------------------------------
    NSConditionLock *lock = [threadDict objectForKey:LOCK_KEY];
    [lock lock];
    [lock unlockWithCondition:1];
    
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    
    //-------------------------------------------------------------------
    // Give the run loop an initial source to keep the CPU from thrashing.
    //-------------------------------------------------------------------
    NSPort *port = [NSPort port];
    [currentRunLoop addPort:port forMode:NSDefaultRunLoopMode];
    
    while (!currentThread.isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [currentRunLoop removePort:port forMode:NSDefaultRunLoopMode];
    
    [pool release];
}

+ (void)stopThread:(NSThread *)thread
{
    if ([NSThread currentThread] == thread)
    {
        [thread cancel];
    }
    else if (thread)
    {
        [self performSelector:_cmd onThread:thread withObject:thread waitUntilDone:NO];
    }
}

@end

//##OBJCLEAN_ENDSKIP##
