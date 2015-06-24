//
//  SAVAccessibilityTextSizeRegistration.h
//  SavantExtensions
//
//  Created by Cameron Pulsford on 12/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SAVAccessibilityTextSizeRegistration : NSObject

+ (UIFont *)fontWithName:(NSString *)family accessibilitySize:(NSString *)size;

- (instancetype)initWithChangeHandler:(dispatch_block_t)changeHandler NS_DESIGNATED_INITIALIZER;

@end
