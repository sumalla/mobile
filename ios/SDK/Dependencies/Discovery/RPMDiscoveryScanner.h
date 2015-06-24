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

//##OBJCLEAN_SKIP##

@import Foundation;
#import "RPMCommunicationConstants.h"

#define     rpmDiscoveryScannerEndpointTimeout       (30)

@protocol RPMDiscoveryScannerDelegate <NSObject>

- (void)foundSavantEndpoint: (NSDictionary*)info;
- (void)lostSavantEndpoint: (NSDictionary*)info;
- (void)updatedSavantEndpoint: (NSDictionary*)info;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMDiscoveryScanner : NSObject
{
    id          _delegate;
    BOOL        _shouldExit;
    NSThread*   _delegateThread;
    NSThread*   _scannerThread;
    int         _s;
    CFSocketRef _socketRef;
    NSDictionary*        _previousEndpoints;
    NSMutableDictionary* _currentEndpoints;
}
#pragma clang diagnostic pop

@property (assign) id delegate;

/**
 *  Starts the scanner.
 */
- (void)startScan;

/**
 *  Stops the scanner.
 */
- (void)stopScan;

@end

//##OBJCLEAN_ENDSKIP##
