//
//  NSSet+MessagePack.m
//  Fetch TV Remote
//
//  Created by Jason Held on 12/19/2013.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

//##OBJCLEAN_SKIP##

#import "NSSet+MessagePack.h"
#import "MessagePackPacker.h"

@implementation NSSet (NSSet_MessagePack)

// Packs the receiver's data into message pack data
- (NSData*)messagePack {
	return [MessagePackPacker pack:self];
}

@end

//##OBJCLEAN_ENDSKIP##
