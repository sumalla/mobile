//
//  UIScreen+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIScreen+SAVExtensions.h"

@implementation UIScreen (SAVExtensions)

+ (CGFloat)screenPixel
{
    return 1 / [UIScreen mainScreen].scale;
}

@end
