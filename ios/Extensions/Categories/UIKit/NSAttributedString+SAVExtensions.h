//
//  stuff.h
//  Savant
//
//  Created by Cameron Pulsford on 3/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

@interface NSAttributedString (SAVExtensions)

+ (NSAttributedString *)sav_attributedStringWithString:(NSString *)string color:(UIColor *)color;

+ (NSAttributedString *)sav_underlinedAttributedStringWithString:(NSString *)string;

@end
