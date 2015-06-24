//
//  rpmThreadUtils.h
//  rpmGeneralUtils
//
//  Created by Cameron Pulsford on 5/6/13.
//
//

#import <Foundation/Foundation.h>

@interface rpmThreadUtils : NSObject

//-------------------------------------------------------------------
//
//   Description
//
//   Return Value
//       A newly created background thread.
//   Notes
//
//-------------------------------------------------------------------
+ (NSThread *)runningThread;

//-------------------------------------------------------------------
//
//   Description
//       Cleanly stop a running thread returned by +runningThread.
//   Return Value
//
//   Notes
//
//-------------------------------------------------------------------
+ (void)stopThread:(NSThread *)thread;

@end
