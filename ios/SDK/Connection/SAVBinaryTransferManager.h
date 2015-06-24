//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2014 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2014 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2014 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

#import <Foundation/Foundation.h>

@protocol SAVBinaryTransferManagerConfigDelegate;

@interface SAVBinaryTransferManager : NSObject

@property (nonatomic, weak) id<SAVBinaryTransferManagerConfigDelegate> configDelegate;

- (void)updateDownloadWithIdentifier:(NSString *)identifier data:(NSData *)data expectedLength:(NSUInteger)expectedLength complete:(BOOL)complete type:(NSUInteger)type;

- (void)invalidate;

@end

@protocol SAVBinaryTransferManagerConfigDelegate <NSObject>

- (void)transferManagerDidFinishUntarringConfig:(SAVBinaryTransferManager *)transferManager;

@end
