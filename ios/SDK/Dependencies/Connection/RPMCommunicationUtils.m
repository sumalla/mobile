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

#import "RPMCommunicationUtils.h"
#import "RPMCommunicationConstants.h"

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmGeneralUtils/MessagePack.h>
#import <rpmGeneralUtils/mfiSharedCocoaExtensions.h>
#else
#import "rpmSharedLogger.h"
#import "MessagePack.h"
#import "mfiSharedCocoaExtensions.h"
#endif

@implementation RPMCommunicationUtils

+ (NSMutableData *)binaryHeaderWithType:(NSUInteger)type size:(NSUInteger)size complete:(BOOL)complete identifer:(id)identifier
{
    NSMutableData *header = [NSMutableData data];
    
    [header appendByte:type]; // 1 byte, security camera type
    [header appendLong:size]; // 4 bytes, data size
    [header appendByte:complete ? 0x01 : 0x00]; // 1 byte, in-complete marker
    
    NSData *session = nil;
    
    if ([identifier isKindOfClass:[NSDictionary class]])
    {
        session = [(NSDictionary *)identifier messagePack];
    }
    else if ([identifier isKindOfClass:[NSString class]])
    {
        identifier = identifier ? identifier : @"";
        session = [(NSString *)identifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        RPMLogErr(@"Unexpected identifier: %@", identifier);
    }
    
    [header appendLong:session.length]; // 4 bytes, session length
    [header appendData:session]; // session id (variable length)
    
    return header;
}

+ (NSString *)createAsyncServiceType:(NSString *)serviceType
                          systemName:(NSString *)systemName
{
    NSString *type = nil;
    
    if (systemName)
    {
        if (serviceType)
        {
            type = [NSString stringWithFormat:@"_%@_%@%@", serviceType, systemName, RPM_ASYNC_SERVICEBASETYPE];
        }
        else
        {
            type = [NSString stringWithFormat:@"_%@%@", systemName, RPM_ASYNC_SERVICEBASETYPE];
        }
    }
    else
    {
        if (serviceType)
        {
            type = [NSString stringWithFormat:@"_%@%@", serviceType, RPM_ASYNC_SERVICEBASETYPE];
        }
        else
        {
            type = [NSString stringWithFormat:@"%@", RPM_ASYNC_SERVICEBASETYPE];
        }
    }
    
    return type;
}

@end
