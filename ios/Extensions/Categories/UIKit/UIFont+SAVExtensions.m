//
//  UIFont+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 4/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIFont+SAVExtensions.h"

@implementation UIFont (SAVExtensions)

- (CGFloat)sav_renderHeight
{
    return [@"Size Me" sizeWithAttributes:@{NSFontAttributeName: self}].height / [UIScreen mainScreen].scale;
}

@end
