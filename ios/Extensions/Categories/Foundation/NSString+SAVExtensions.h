//
//  NSString+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@import UIKit;
#endif

extern NSStringCompareOptions const NSCaseInsensitiveNumericSearch;

@interface NSString (SAVExtensions)

- (BOOL)sav_containsString:(NSString *)aString options:(NSStringCompareOptions)mask;

- (BOOL)sav_containsString:(NSString *)aString options:(NSStringCompareOptions)mask range:(NSRange)searchRange;

- (BOOL)sav_isValidEmail;

- (BOOL)sav_isValidPassword;

- (NSInteger)computeLevenshteinDistanceWithString:(NSString *)string;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (CGSize)sav_sizeWithFont:(UIFont *)font;

- (CGRect)sav_rectWithFont:(UIFont *)font;
#endif

@end
