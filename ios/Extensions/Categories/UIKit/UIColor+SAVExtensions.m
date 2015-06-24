//
//  UIColor+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIColor+SAVExtensions.h"

@implementation UIColor (SAVExtensions)

+ (instancetype)sav_colorWithRGBValue:(uint32_t)rgbValue alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:(CGFloat)(((rgbValue & 0xFF0000) >> 16) / 255.0)
                           green:(CGFloat)(((rgbValue & 0xFF00) >> 8) / 255.0)
                            blue:(CGFloat)((rgbValue & 0xFF) / 255.0)
                           alpha:alpha];
}

+ (instancetype)sav_colorWithRGBValue:(uint32_t)rgbValue
{
    return [[self class] sav_colorWithRGBValue:rgbValue alpha:1.0];
}

- (instancetype)sav_blendColor:(UIColor *)blendColor intensity:(CGFloat)intensity
{
    //--------------------------------------------------
    // Clamp intensity to [0...1]
    //--------------------------------------------------
    intensity = MAX(MIN(1.0, intensity), 0.0);

    if (intensity == 0.0)
    {
        return self;
    }

    if (intensity == 1.0)
    {
        return blendColor;
    }

    //--------------------------------------------------
    // Blend the colors.
    //--------------------------------------------------
    CGFloat sourceR, sourceG, sourceB, sourceA;
    CGFloat blendR, blendG, blendB, blendA;

    [self getRed:&sourceR green:&sourceG blue:&sourceB alpha:&sourceA];
    [blendColor getRed:&blendR green:&blendG blue:&blendB alpha:&blendA];

    CGFloat sourceIntensity = 1 - intensity;
    CGFloat blendIntensity = intensity;

    return [UIColor colorWithRed:sourceR * sourceIntensity + blendR * blendIntensity
                           green:sourceG * sourceIntensity + blendG * blendIntensity
                            blue:sourceB * sourceIntensity + blendB * blendIntensity
                           alpha:sourceA * sourceIntensity + blendA * blendIntensity];
}

#pragma mark - Debugging helpers

+ (instancetype)sav_randomColor
{
    CGFloat hue = (arc4random() % 256 / 256.0);
    CGFloat saturation = (arc4random() % 128 / 256.0) + 0.5;
    CGFloat brightness = (arc4random() % 128 / 256.0) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@end
