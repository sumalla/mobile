//
//  MessagePackParser.m
//  Fetch TV Remote
//
//  Created by Chris Hulbert on 23/06/11.
//  Copyright 2011 Digital Five. All rights reserved.
//

//##OBJCLEAN_SKIP##

#import "MessagePackParser.h"
#import "MessagePackPacker.h"
#include "msgpack_src/msgpack.h"

@implementation MessagePackParser

+ (NSDate *)dateFromString:(NSString *)dateString
{
    NSDate *date = [[MessagePackPacker sharedDateFormatter] dateFromString:dateString];

    NSString *localDateString = [[MessagePackPacker sharedLocalDateFormatter] stringFromDate:date];

    return [[MessagePackPacker sharedLocalDateFormatter] dateFromString:localDateString];
}

// This function returns a parsed object that you have the responsibility to release/autorelease (see 'create rule' in apple docs)
+(id) createUnpackedObject:(msgpack_object)obj NS_RETURNS_RETAINED {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (obj.type) {
        case MSGPACK_OBJECT_BOOLEAN:
            return [[NSNumber alloc] initWithBool:obj.via.boolean];
        case MSGPACK_OBJECT_POSITIVE_INTEGER:
            return [[NSNumber alloc] initWithUnsignedLongLong:obj.via.u64];
        case MSGPACK_OBJECT_NEGATIVE_INTEGER:
            return [[NSNumber alloc] initWithLongLong:obj.via.i64];
        case MSGPACK_OBJECT_DOUBLE:
            return [[NSNumber alloc] initWithDouble:obj.via.dec];
        case MSGPACK_OBJECT_RAW:
            return [[NSString alloc] initWithBytes:obj.via.raw.ptr length:obj.via.raw.size encoding:NSUTF8StringEncoding];
        case MSGPACK_OBJECT_ARRAY:
        {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:obj.via.array.size];
            msgpack_object* const pend = obj.via.array.ptr + obj.via.array.size;
            msgpack_object *p;
            for(p = obj.via.array.ptr;p < pend;p++){
				id newArrayItem = [self createUnpackedObject:*p];
                [arr addObject:newArrayItem];
                [newArrayItem release];
            }
            return arr;
        }
        case MSGPACK_OBJECT_MAP:
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:obj.via.map.size];
            msgpack_object_kv* const pend = obj.via.map.ptr + obj.via.map.size;
            msgpack_object_kv* p;
            for(p = obj.via.map.ptr; p < pend; p++){
                id key = [self createUnpackedObject:p->key];
                id val = [self createUnpackedObject:p->val];
                [dict setValue:val forKey:key];
				[key release];
				[val release];
            }
            return dict;
        }
        case MSGPACK_OBJECT_NIL:
        default:
            return [NSNull null]; // Since nsnull is a system singleton, we don't have to worry about ownership of it
    }
#pragma clang diagnostic pop
}

// Parse the given messagepack data into a NSDictionary or NSArray typically
+ (id)parseData:(NSData*)data {
	msgpack_unpacked msg;
	msgpack_unpacked_init(&msg);
	bool success = msgpack_unpack_next(&msg, data.bytes, data.length, NULL); // Parse it into C-land
	id results = success ? [self createUnpackedObject:msg.data] : nil; // Convert from C-land to Obj-c-land
	msgpack_unpacked_destroy(&msg); // Free the parser
	return [results autorelease];
}

@end

//##OBJCLEAN_ENDSKIP##
