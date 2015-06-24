//
//  SCUSecondsPickerView.m
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecondsPickerView.h"
@import Extensions;

@implementation SCUSecondsPickerView

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [SCUSecondsPickerView stringForValue:[self valueForRow:row]];
}

+ (NSString *)stringForValue:(NSTimeInterval)value
{
    BOOL isNegative = value < 0;

    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:ABS(value)];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]
                                                     toDate:date
                                                    options:0];


    NSString *title = @"";

    if ([dateComponents year] > 0)
    {
        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents year], [dateComponents year] > 1 ? NSLocalizedString(@"Years", nil) : NSLocalizedString(@"Year", nil)];
    }

    if ([dateComponents month] > 0)
    {
        if ([title length])
        {
            title = [title stringByAppendingString:@", "];
        }

        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents month], [dateComponents month] > 1 ? NSLocalizedString(@"Months", nil) : NSLocalizedString(@"Month", nil)];
    }

    if ([dateComponents day] > 0)
    {
        if ([title length])
        {
            title = [title stringByAppendingString:@", "];
        }

        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents day], [dateComponents day] > 1 ? NSLocalizedString(@"Days", nil) : NSLocalizedString(@"Day", nil)];
    }

    if ([dateComponents hour] > 0)
    {
        if ([title length])
        {
            title = [title stringByAppendingString:@", "];
        }

        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents hour], [dateComponents hour] > 1 ? NSLocalizedString(@"Hours", nil) : NSLocalizedString(@"Hour", nil)];
    }

    if ([dateComponents minute] > 0)
    {
        if ([title length])
        {
            title = [title stringByAppendingString:@", "];
        }

        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents minute], [dateComponents minute] > 1 ? NSLocalizedString(@"Minutes", nil) : NSLocalizedString(@"Minute", nil)];
    }

    if ([dateComponents second] > 0)
    {
        if ([title length])
        {
            title = [title stringByAppendingString:@", "];
        }

        title = [title stringByAppendingFormat:@"%ld %@", (long)[dateComponents second], [dateComponents second] > 1 ? NSLocalizedString(@"Seconds", nil) :  NSLocalizedString(@"Second", nil)];
    }

    if (![title length])
    {
        title = NSLocalizedString(@"None", nil);
    }
    else if (isNegative)
    {
        title = [@"-" stringByAppendingString:title];
    }
    
    return title;
}

@end
