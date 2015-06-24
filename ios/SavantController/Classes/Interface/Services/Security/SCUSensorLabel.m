//
//  SCUSensorLabel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSensorLabel.h"

#import <SavantExtensions/SavantExtensions.h>

@implementation SCUSensorLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.font = [UIFont fontWithName:@"Gotham-Medium" size:11];
        self.textColor = [UIColor sav_colorWithRGBValue:0x020000];
        self.textAlignment = NSTextAlignmentCenter;
        self.layer.cornerRadius = 12;
        self.clipsToBounds = YES;
    }
    return self;
}

@end
