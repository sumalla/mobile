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

#import "RPMWebSocketFragment.h"

@interface RPMWebSocketFragment ()

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic) size_t remaining;

@end

@implementation RPMWebSocketFragment

@synthesize data = _data;
@synthesize remaining = _remaining;

+ (RPMWebSocketFragment *)fragmentWithBytes:(void *)bytes
                                     length:(size_t)length
                                  remaining:(size_t)remaining
{
    return [[[RPMWebSocketFragment alloc] initWithBytes:bytes
                                                 length:length
                                              remaining:remaining] autorelease];
}

- (id)initWithBytes:(void *)bytes
             length:(size_t)length
          remaining:(size_t)remaining
{
    self = [super init];
    if (self)
    {
        self.data = [NSMutableData dataWithBytes:bytes length:length];
        self.remaining = remaining;
    }

    return self;
}

- (void)dealloc
{
    self.data = nil;
    [super dealloc];
}

- (void)appendBytes:(void *)bytes
             length:(size_t)length
{
    [self.data appendBytes:bytes length:length];
    self.remaining -= length;
}

@end