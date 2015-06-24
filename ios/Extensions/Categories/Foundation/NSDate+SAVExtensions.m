//
//  NSDate+SAVExtensions.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "NSDate+SAVExtensions.h"

NSCalendarUnit const NSCalendarUnitDate = (NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);

@implementation NSDate (SAVExtensions)

- (NSDate *)dateWithoutTimeComponents
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDate fromDate:self];

    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (BOOL)isToday
{
    return [[self dateWithoutTimeComponents] isEqualToDate:[NSDate today]];
}

+ (NSDate *)today
{
    return [[NSDate date] dateWithoutTimeComponents];
}

@end
