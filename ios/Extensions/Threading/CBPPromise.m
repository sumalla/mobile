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

#import "CBPPromise.h"
#import "CBPDerefSubclass.h"
#import "NSThread+CBPExtensions.h"

id const CBPPromiseTimeoutValue = @"CBPPromiseTimeoutValue";

@interface CBPPromise ()

@property (weak) NSTimer *timeoutTimer;

@end

@implementation CBPPromise

+ (NSThread *)sharedPromiseTimerThread
{
    static NSThread *sharedPromiseTimerThread = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPromiseTimerThread = [NSThread cbp_runningThread];
    });

    return sharedPromiseTimerThread;
}

- (void)dealloc
{
    [self invalidateWithError:nil];
}

- (instancetype)initWithTimeout:(NSTimeInterval)timeout
{
    if (timeout <= 0)
    {
        [NSException raise:NSInvalidArgumentException format:@"A CBPPromise timeout value must be greater than 0."];
    }
    else
    {
        self = [super init];

        if (self)
        {
            [[[self class] sharedPromiseTimerThread] cbp_performBlockSync:^{

                self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                     target:self
                                                                   selector:@selector(invalidate:)
                                                                   userInfo:nil
                                                                    repeats:NO];

            }];
        }
    }

    return self;
}

- (BOOL)deliver:(id)value
{
    return [self _deliver:value];
}

#pragma mark -

- (BOOL)_deliver:(id)value
{
    BOOL delivered = [self assignValue:value];

    if (self.timeoutTimer)
    {
        [[[self class] sharedPromiseTimerThread] cbp_performBlockSync:^{
            [self.timeoutTimer invalidate];
        }];
    }

    return delivered;
}

- (void)invalidate:(NSTimer *)timer
{
    [self _deliver:CBPPromiseTimeoutValue];
}

@end
