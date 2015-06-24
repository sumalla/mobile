//
//  Stuff.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 10/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSData+SAVExtensions.h"

@implementation NSData (SAVExtensions)

- (NSString *)hexRepresentation
{
    NSMutableString *value = [NSMutableString string];

    const unsigned char *bytes = (const unsigned char*)[self bytes];

    for (NSUInteger i = 0; i < [self length]; i++)
    {
        [value appendFormat:@"%02x", bytes[i]];
    }

    return [value copy];
}

@end
