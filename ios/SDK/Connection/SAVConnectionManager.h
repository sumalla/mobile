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
#import "SAVConnectionState.h"

@class SAVConnection, SAVSystem;

@interface SAVConnectionManager : NSObject

/**
 *  The current system.
 */
@property (nonatomic) SAVSystem *system;

/**
 *  The current connection state.
 */
@property (readonly, nonatomic) SAVConnectionState connectionState;

/**
 *  The current connection.
 */
@property (readonly) SAVConnection *connection;

/**
 *  Start the connection manager.
 */
- (void)start;

/**
 *  Stop the connection manager.
 */
- (void)stop;

/**
 *  Promotes the current system to a cloud system.
 */
- (void)promoteCurrentSystemToACloudSystem;

@end
