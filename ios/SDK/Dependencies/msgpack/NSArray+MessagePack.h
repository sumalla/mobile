//
//  NSArray+MessagePack.h
//  Fetch TV Remote
//
//  Created by Chris Hulbert on 13/10/11.
//  Copyright (c) 2011 Digital Five. All rights reserved.
//

//##OBJCLEAN_SKIP##

@import Foundation;

// Adds MessagePack packing to NSArray
@interface NSArray (NSArray_MessagePack)

// Packs the receiver's data into message pack data
- (NSData*)messagePack;

@end

//##OBJCLEAN_ENDSKIP##
