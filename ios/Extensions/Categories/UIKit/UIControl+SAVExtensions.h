//
//  UIControl+SAVExtensions.h
//  SavantExtensions
//
//  Created by Cameron Pulsford on 7/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIControl (SAVExtensions)

- (void)sav_forControlEvent:(UIControlEvents)controlEvent performBlock:(dispatch_block_t)block;

@end
