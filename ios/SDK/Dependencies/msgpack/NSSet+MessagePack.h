//
//  NSSet+MessagePack.h
//  Fetch TV Remote
//
//  Created by Jason Held on 12/19/2013.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

//##OBJCLEAN_SKIP##

@import Foundation;

// Adds MessagePack packing to NSSet
@interface NSSet (NSSet_MessagePack)

// Packs the receiver's data into message pack data
- (NSData*)messagePack;

@end

//##OBJCLEAN_ENDSKIP##
