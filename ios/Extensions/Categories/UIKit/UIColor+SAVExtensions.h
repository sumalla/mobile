//
//  UIColor+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SAVCollectionViewColors)
{
    SAVCollectionViewColorsCoastal,
    SAVCollectionViewColorsPlatinum
};

@interface UIColor (SAVExtensions)

+ (instancetype)sav_colorWithRGBValue:(uint32_t)rgbValue alpha:(CGFloat)alpha;

+ (instancetype)sav_colorWithRGBValue:(uint32_t)rgbValue;

/**
 *  Blends the receiver with blendColor
 *
 *  @param blendColor The color to blend with the receiver.
 *  @param intensity  The intensity with which to mix in the blendColor. Values should be in the range [0...1]. 0 results in the same color. 1 results in blendColor.
 *
 *  @return The blended color.
 */
- (instancetype)sav_blendColor:(UIColor *)blendColor intensity:(CGFloat)intensity;

#pragma mark - Debugging helpers

+ (instancetype)sav_randomColor;

@end
