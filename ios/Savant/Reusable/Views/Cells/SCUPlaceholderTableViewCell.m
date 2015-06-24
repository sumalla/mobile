//
//  SCUSystemSelectorEmptyTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPlaceholderTableViewCell.h"

@implementation SCUPlaceholderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textLabel.textColor = [[[SCUColors shared] color04] colorWithAlphaComponent:0.4];
        self.textLabel.numberOfLines = 0;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

@end
