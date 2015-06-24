//
//  SCUMediaMessageTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaMessageTableViewCell.h"

@implementation SCUMediaMessageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textLabel.numberOfLines = 0;
    }

    return self;
}

@end
