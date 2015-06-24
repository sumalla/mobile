//
//  stuff.m
//  Savant
//
//  Created by Cameron Pulsford on 3/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "NSAttributedString+SAVExtensions.h"

@implementation NSAttributedString (SAVExtensions)

+ (NSAttributedString *)sav_attributedStringWithString:(NSString *)string color:(UIColor *)color
{
    NSParameterAssert(string);
    NSParameterAssert(color);
    return [[NSAttributedString alloc] initWithString:string attributes:@{NSForegroundColorAttributeName: color}];
}

+ (NSAttributedString *)sav_underlinedAttributedStringWithString:(NSString *)string
{
    NSParameterAssert(string);
    return [[NSAttributedString alloc] initWithString:string attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
}

@end
