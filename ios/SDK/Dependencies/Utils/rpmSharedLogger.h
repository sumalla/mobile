//
//  rpmSharedLogger.h
//  SavantUI
//
//  Created by Nathan Trapp on 2/4/13.
//  Copyright (c) 2013 Savant Systems LLC. All rights reserved.
//

@import Foundation;
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelOff;
#else
static const DDLogLevel ddLogLevel = DDLogLevelError;
#endif

/*
 Convenience Functions
 */
#define RPMLogEmerg(format, ...)   DDLogError(format, ##__VA_ARGS__)
#define RPMLogAlert(format, ...)   DDLogError(format, ##__VA_ARGS__)
#define RPMLogCrit(format, ...)    DDLogError(format, ##__VA_ARGS__)
#define RPMLogErr(format, ...)     DDLogError(format, ##__VA_ARGS__)
#define RPMLogWarning(format, ...) DDLogWarn(format, ##__VA_ARGS__)
#define RPMLogNotice(format, ...)  DDLogInfo(format, ##__VA_ARGS__)
#define RPMLogInfo(format, ...)    DDLogDebug(format, ##__VA_ARGS__)
#define RPMLogDebug(format, ...)   DDLogVerbose(format, ##__VA_ARGS__)