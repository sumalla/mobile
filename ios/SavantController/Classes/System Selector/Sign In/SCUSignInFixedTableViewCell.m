//
//  SCUSignInFixedTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSignInFixedTableViewCell.h"

@implementation SCUSignInFixedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

@end
