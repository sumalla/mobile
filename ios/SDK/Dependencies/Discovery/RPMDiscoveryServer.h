//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2013 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2013 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2013 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

@import Foundation;
#import "RPMCommunicationConstants.h"

typedef enum
{
    rpmDiscovery_OSX = 0,
    rpmDiscovery_Linux = 1,
} rpmDiscovery_t;

extern uint32_t const RPM_CURRENT_DISCOVERY_VERSION;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMDiscoveryServer : NSObject
{
    NSString       *_UID;
    NSString       *_name;
    NSUInteger     _port;
    NSString       *_scheme;
    NSString       *_interfaceLaunchProgressStateName;
    NSUInteger     _interfaceLaunchProgressStateValue;
    rpmDiscovery_t _type;
    NSThread       *_serverThread;
    BOOL           _shouldExit;
    NSTimer        *_publishRetryTimer;
    int            _socket;
}
#pragma clang diagnostic pop

@property (retain, nonatomic) NSString *UID;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *scheme;
@property (assign, nonatomic) NSUInteger port;
@property (readonly) rpmDiscovery_t type;

- (id)initWithUID:(NSString *)uid
             port:(NSUInteger)port
             name:(NSString *)name
           scheme:(NSString *)scheme;
- (void)invalidate;
- (void)startServer;

@end
