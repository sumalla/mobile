//
//  MessagePackParser.h
//  Fetch TV Remote
//
//  Created by Chris Hulbert on 23/06/11.
//  Copyright 2011 Digital Five. All rights reserved.
//

//##OBJCLEAN_SKIP##

@import Foundation;

@interface MessagePackParser : NSObject

//-------------------------------------------------------------------
// Uses MessagePackPacker's sharedDateFormatter
//-------------------------------------------------------------------
+ (NSDate *)dateFromString:(NSString *)dateString;

+ (id)parseData:(NSData*)data;

@end

//##OBJCLEAN_ENDSKIP##
