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

#import "CBPDeref.h"
#import "CBPDerefSubclass.h"

typedef NS_ENUM(NSInteger, CBPPromiseLockState_t)
{
    CBPDerefLockStateWaiting,
    CBPDerefLockStateRealized,
};

id const CBPDerefInvalidValue = @"CBPDerefInvalidValue";

@interface CBPDeref ()

@property (nonatomic) NSConditionLock *lock;

@property (nonatomic) id value;

@property CBPDerefState state;

@property (getter = isRealized) BOOL realized;

@property (getter = isValid) BOOL valid;

@end

@implementation CBPDeref

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.valid = YES;
        self.state = CBPDerefStateIncomplete;
        self.lock = [[NSConditionLock alloc] initWithCondition:CBPDerefLockStateWaiting];
    }

    return self;
}

- (id)deref
{
    if ([self.lock condition] != CBPDerefLockStateRealized)
    {
        [self.lock lockWhenCondition:CBPDerefLockStateRealized];
        [self.lock unlock];
    }

    return self.value;
}

- (id)derefWithTimeoutInterval:(NSTimeInterval)timeoutInterval timeoutValue:(id)timeoutValue
{
    BOOL timedout = NO;

    if ([self.lock condition] != CBPDerefLockStateRealized)
    {
        if ([self.lock lockWhenCondition:CBPDerefLockStateRealized beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeoutInterval]])
        {
            [self.lock unlock];
        }
        else
        {
            timedout = YES;
        }
    }

    return timedout ? timeoutValue : self.value;
}

- (BOOL)invalidateWithError:(NSError *)error
{
    return [self assignValue:CBPDerefInvalidValue error:error notify:YES newState:CBPDerefStateInvalid criticalBlock:NULL];
}

#pragma mark - CBPDerefSubclass methods

- (BOOL)assignValue:(id)value
{
    return [self assignValue:value error:nil notify:YES newState:CBPDerefStateComplete criticalBlock:NULL];
}

- (BOOL)valueHasBeenAssigned
{
    return [self.lock condition] == CBPDerefLockStateRealized;
}

#pragma mark -

- (BOOL)assignValue:(id)value error:(NSError *)error notify:(BOOL)notify newState:(CBPDerefState)newState criticalBlock:(dispatch_block_t)criticalBlock
{
    BOOL success = NO;

    if ([self.lock tryLockWhenCondition:CBPDerefLockStateWaiting])
    {
        success = YES;

        @synchronized (self)
        {
            self.state = newState;
            self.value = value;
            self.realized = YES;
            [self.lock unlockWithCondition:CBPDerefLockStateRealized];

            if (criticalBlock)
            {
                criticalBlock();
            }

            if (notify)
            {
                dispatch_block_t block = NULL;

                if (newState == CBPDerefLockStateRealized)
                {
                    if (self.successBlock)
                    {
                        CBPDerefSuccessBlock successBlock = self.successBlock;

                        block = ^{
                            successBlock(value);
                        };
                    }
                }
                else if (newState == CBPDerefStateInvalid)
                {
                    self.valid = NO;
                    
                    if (self.invalidBlock)
                    {
                        CBPDerefInvalidBlock invalidBlock = self.invalidBlock;

                        block = ^{
                            invalidBlock(error);
                        };
                    }
                }

                if (block)
                {
                    dispatch_queue_t dispatchQueue = self.callbackQueue ? self.callbackQueue : dispatch_get_main_queue();
                    dispatch_async(dispatchQueue, block);
                }
            }
            
            self.successBlock = NULL;
            self.invalidBlock = NULL;
            self.callbackQueue = NULL;
        }
    }
    
    return success;
}

@end
