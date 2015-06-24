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

@import Foundation;

typedef NS_ENUM(NSUInteger, CBPDerefState)
{
    CBPDerefStateIncomplete,
    CBPDerefStateComplete,
    CBPDerefStateInvalid
};

typedef void (^CBPDerefSuccessBlock)(id value);

typedef void (^CBPDerefInvalidBlock)(NSError *error);

extern id const CBPDerefInvalidValue;

@interface CBPDeref : NSObject

/**
 *  Returns the current state of the deref.
 */
@property (readonly) CBPDerefState state;

/**
 *  Returns YES if the deref is complete, or has been invalidated; otherwise, NO.
 */
@property (readonly, getter = isRealized) BOOL realized;

/**
 *  Returns YES if the deref is valid; otherwise, NO.
 */
@property (readonly, getter = isValid) BOOL valid;

/**
 *  Waits indefinitely until the deref has been realized or invalidated.
 *
 *  @return The realized value.
 */
- (id)deref;

/**
 *  Blocks until a value has been realized, or the timeout has expired.
 *
 *  @param timeoutInterval The amount of time to block.
 *  @param timeoutValue    The value returned if the timeout is reached before a value has been realized.
 *
 *  @return The realized value or @p timeoutValue if a value was not realized in the given time.
 */
- (id)derefWithTimeoutInterval:(NSTimeInterval)timeoutInterval timeoutValue:(id)timeoutValue;

/**
 *  Invalidate the deref so that no values can be realized. @p -deref and @p -derefWithTimeoutInterval:timeoutValue: will both return @p CBPDerefInvalidValue.
 *
 *  @param error The reason for invalidating the deref, or nil.
 *
 *  @return YES if the promise could be invalidated; otherwise, NO.
 */
- (BOOL)invalidateWithError:(NSError *)error;

/**
 *  This block will be called when the deref's value has been realized.
 */
@property (copy) CBPDerefSuccessBlock successBlock;

/**
 *  This block will be called when a deref is invalidated.
 */
@property (copy) CBPDerefInvalidBlock invalidBlock;

/**
 *  The queue on which to perform the success/invalid blocks. If no queue is specified, the main queue will be used.
 */
@property dispatch_queue_t callbackQueue;

@end
