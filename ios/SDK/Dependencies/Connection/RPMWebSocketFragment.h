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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMWebSocketFragment : NSObject
{
    NSMutableData *_data;
    size_t        _remaining;
}
#pragma clang diagnostic pop

+ (RPMWebSocketFragment *)fragmentWithBytes:(void *)bytes
                                     length:(size_t)length
                                  remaining:(size_t)remaining;

- (id)initWithBytes:(void *)bytes
             length:(size_t)length
          remaining:(size_t)remaining;

- (void)appendBytes:(void *)bytes
             length:(size_t)length;

@property (nonatomic, retain, readonly) NSMutableData *data;
@property (nonatomic, readonly) size_t remaining;

@end
