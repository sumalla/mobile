//
//  SCUCameraHeaderCell.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraHeaderCell.h"

#import <SavantExtensions/SavantExtensions.h>

@implementation SCUCameraHeaderCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:32];
        self.textLabel.textColor = [UIColor sav_colorWithRGBValue:0x909090];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                               metrics:nil
                                                                                 views:@{@"label": self.textLabel}
                                                                                formats:@[@"|-(5)-[label]",
                                                                                          @"V:|[label]|"]]];
    }
    return self;
}

@end
