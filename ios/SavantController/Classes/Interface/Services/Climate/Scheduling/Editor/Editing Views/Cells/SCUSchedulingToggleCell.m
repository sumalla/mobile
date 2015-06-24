//
//  SCUSchedulingToggleCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingToggleCell.h"

@implementation SCUSchedulingToggleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.accessoryView = nil;

        [self.contentView addSubview:self.toggleSwitch];
        [self.contentView sav_pinView:self.toggleSwitch withOptions:SAVViewPinningOptionsToRight withSpace:26];
        [self.contentView sav_pinView:self.toggleSwitch withOptions:SAVViewPinningOptionsToTop withSpace:10];
    }
    return self;
}

@end
