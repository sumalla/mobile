//
//  UIButton+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIButton+SAVExtensions.h"
#import "SAVUtils.h"
#import "UIImage+SAVExtensions.h"

@implementation UIButton (SAVExtensions)

- (void)sav_setBackgroundImage:(UIImage *)image forStates:(NSArray *)states
{
    for (NSNumber *state in states)
    {
        [self setBackgroundImage:image forState:[state unsignedIntegerValue]];
    }
}

- (void)sav_setTitleColor:(UIColor *)color forStates:(NSArray *)states
{
    for (NSNumber *state in states)
    {
        [self setTitleColor:color forState:[state unsignedIntegerValue]];
    }
}

- (void)sav_setTitle:(NSString *)title forStates:(NSArray *)states
{
    for (NSNumber *state in states)
    {
        [self setTitle:title forState:[state unsignedIntegerValue]];
    }
}

- (void)sav_setImage:(UIImage *)image forStates:(NSArray *)states
{
    for (NSNumber *state in states)
    {
        [self setImage:image forState:[state unsignedIntegerValue]];
    }
}

- (void)sav_setColor:(UIColor *)color forState:(UIControlState)state
{
    [self setBackgroundImage:[UIImage resizableImageOfColor:color initialSize:1] forState:state];
}

@end
