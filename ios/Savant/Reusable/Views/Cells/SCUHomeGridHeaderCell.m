//
//  SCUHomeGridHeaderCell.m
//  SavantController
//
//  Created by Nathan Trapp on 6/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeGridHeaderCell.h"

@import Extensions;

@implementation SCUHomeGridHeaderCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:14];
        self.textLabel.textColor = [UIColor sav_colorWithRGBValue:0x989898];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:nil
                                                                                  views:@{@"label": self.textLabel}
                                                                                formats:@[@"|-(5)-[label]",
                                                                                          @"V:|[label]|"]]];
    }
    return self;
}

- (void)configureWithInfo:(id)info
{
    self.textLabel.text = [info[SCUDefaultCollectionViewCellKeyTitle] uppercaseString];
}

@end
