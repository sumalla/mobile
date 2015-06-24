//
//  NSString+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "NSString+SAVExtensions.h"

NSStringCompareOptions const NSCaseInsensitiveNumericSearch = (NSStringCompareOptions)(NSCaseInsensitiveSearch | NSNumericSearch);

@implementation NSString (SAVExtensions)

- (BOOL)sav_containsString:(NSString *)aString options:(NSStringCompareOptions)mask
{
    return [self rangeOfString:aString options:mask].location != NSNotFound;
}

- (BOOL)sav_containsString:(NSString *)aString options:(NSStringCompareOptions)mask range:(NSRange)searchRange
{
    return [self rangeOfString:aString options:mask range:searchRange].location != NSNotFound;
}

- (BOOL)sav_isValidEmail
{
    //-------------------------------------------------------------------
    // Got this from here on 2014/8/20: http://stackoverflow.com/a/1149894
    //-------------------------------------------------------------------
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (BOOL)sav_isValidPassword
{
    if ([self length] < 8 ||
     [self rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound ||
     [self rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location == NSNotFound ||
     [self rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == NSNotFound)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

//adapted from Stefano Pigozzi
//https://github.com/pigoz/imal/blob/master/NSString%2BLevenshtein.m
- (NSInteger)computeLevenshteinDistanceWithString:(NSString *)string
{
    NSInteger *d; // distance vector
    NSInteger i, j, k; // indexes
    NSInteger cost;
    NSInteger distance = NSNotFound;
    
    NSInteger n = (NSInteger)[self length];
    NSInteger m = (NSInteger)[string length];
    
    if (n != 0 && m != 0)
    {
        d = malloc(sizeof(NSInteger) * (NSUInteger)(++n) * (NSUInteger)(++m));
        
        for (k = 0; k < n; k++)
        {
            d[k] = k;
        }
        for (k = 0; k < m; k++)
        {
            d[k * n] = k;
        }
        for (i = 1; i < n; i++)
        {
            for (j = 1; j < m; j++)
            {
                if ([self characterAtIndex:(NSUInteger)i - 1] == [string characterAtIndex:(NSUInteger)j - 1])
                {
                    cost = 0;
                }
                else
                {
                    cost = 1;
                }

                d[j * n + i] = MIN(MIN((d[(j - 1) * n + i] + 1),
                                       (d[j * n + i - 1] + 1)),
                                   (d[(j - 1) * n + i - 1] + cost));
            }
        }

        distance = d[n * m - 1];
        free(d);
    }
    
    return distance;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (CGSize)sav_sizeWithFont:(UIFont *)font
{
    NSParameterAssert(font);
    return [[NSAttributedString alloc] initWithString:self attributes:@{NSFontAttributeName: font}].size;
}

- (CGRect)sav_rectWithFont:(UIFont *)font
{
    CGRect rect = CGRectZero;
    rect.size = [self sav_sizeWithFont:font];
    return rect;
}
#endif

@end
