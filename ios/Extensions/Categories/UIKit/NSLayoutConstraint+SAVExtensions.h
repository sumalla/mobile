//
//  NSLayoutConstraint+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface NSLayoutConstraint (SAVExtensions)

+ (NSArray *)sav_constraintsWithMetrics:(NSDictionary *)metrics views:(NSDictionary *)views formats:(NSArray *)formats;
+ (NSArray *)sav_constraintsWithOptions:(NSLayoutFormatOptions)opts metrics:(NSDictionary *)metrics views:(NSDictionary *)views formats:(NSArray *)formats;

@end
