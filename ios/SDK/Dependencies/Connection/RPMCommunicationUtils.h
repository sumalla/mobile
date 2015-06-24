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

#import <Foundation/Foundation.h>

@interface RPMCommunicationUtils : NSObject

+ (NSMutableData *)binaryHeaderWithType:(NSUInteger)type size:(NSUInteger)size complete:(BOOL)complete identifer:(id)identifier;

+ (NSString *)createAsyncServiceType:(NSString *)serviceType
                          systemName:(NSString *)systemName;

@end
