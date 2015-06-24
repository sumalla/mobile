//
//  NSLayoutConstraint+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSLayoutConstraint+SAVExtensions.h"
#import "CompactConstraint.h"

@implementation NSLayoutConstraint (SAVExtensions)

+ (NSArray *)sav_constraintsWithMetrics:(NSDictionary *)metrics views:(NSDictionary *)views formats:(NSArray *)formats
{
    return [[self class] sav_constraintsWithOptions:0 metrics:metrics views:views formats:formats];
}

+ (NSArray *)sav_constraintsWithOptions:(NSLayoutFormatOptions)opts metrics:(NSDictionary *)metrics views:(NSDictionary *)views formats:(NSArray *)formats
{
    NSMutableArray *constraints = [NSMutableArray array];

    static NSRegularExpression *expression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        expression = [[NSRegularExpression alloc] initWithPattern:@"\\.(left|right|top|bottom|leading|trailing|width|height|centerX|centerY|baseline)"
                                                          options:0
                                                            error:NULL];
    });

    for (UIView *view in [views allValues])
    {
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }

    for (NSString *format in formats)
    {
        BOOL compactConstraint = [expression rangeOfFirstMatchInString:format options:0 range:NSMakeRange(0, [format length])].location == NSNotFound ? NO : YES;

        if (compactConstraint)
        {
            [constraints addObject:[NSLayoutConstraint compactConstraint:format metrics:metrics views:views self:nil]];
        }
        else
        {
            [constraints addObjectsFromArray:[[self class] constraintsWithVisualFormat:format options:opts metrics:metrics views:views]];
        }
    }

    return [constraints copy];
}

@end
