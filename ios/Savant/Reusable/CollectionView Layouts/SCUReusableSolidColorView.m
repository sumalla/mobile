//
//  SCUReusableSolidColorView.m
//  SavantController
//
//  Created by Nathan Trapp on 5/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGradientView.h"
#import "SCUReusableSolidColorView.h"

@import Extensions;

@implementation SCUReusableSolidColorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor sav_colorWithRGBValue:0x1e1e1e];
    }
    return self;
}

+ (NSString *)kind
{
    return @"GradientView";
}

@end
