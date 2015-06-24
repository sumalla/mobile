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

@interface NSThread (CBPExtensions)

/**
 *  Creates and returns a new thread that is ready for events to be scheduled on it. To correctly stop it, call -cbp_stop.
 *
 *  @return a newly created thread
 */
+ (NSThread *)cbp_runningThread;

/**
 *  Cleanly stops a thread returned by cbp_runningThread.
 */
- (void)cbp_stop;

/**
 *  Performs a block synchronously on the receiving thread.
 *
 *  @param block the block to perform
 */
- (void)cbp_performBlockSync:(dispatch_block_t)block;

/**
 *  Performs a block asynchronously on the receiving thread. If the target thread and the current thread are the same, the block will be performed on the next iteration of the runloop.
 *
 *  @param block the block to perform
 */
- (void)cbp_performBlockAsync:(dispatch_block_t)block;

@end
