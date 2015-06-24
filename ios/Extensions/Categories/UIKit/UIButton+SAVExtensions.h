//
//  UIButton+SAVExtensions.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIButton (SAVExtensions)

- (void)sav_setBackgroundImage:(UIImage *)image forStates:(NSArray *)states;
- (void)sav_setTitleColor:(UIColor *)color forStates:(NSArray *)states;
- (void)sav_setTitle:(NSString *)title forStates:(NSArray *)states;
- (void)sav_setImage:(UIImage *)image forStates:(NSArray *)states;
- (void)sav_setColor:(UIColor *)color forState:(UIControlState)state;

@end
