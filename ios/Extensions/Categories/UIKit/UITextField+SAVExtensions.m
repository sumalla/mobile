//
//  UITextField+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UITextField+SAVExtensions.h"

@implementation UITextField (SAVExtensions)

- (void)sav_setPlaceholderText:(NSString *)text color:(UIColor *)color
{
    if (text)
    {
        self.placeholder = text;
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: color}];
    }
}

@end
