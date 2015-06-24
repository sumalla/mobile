//
//  SCUSceneVariantCell.m
//  SavantController
//
//  Created by Nathan Trapp on 8/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneVariantCell.h"

@implementation SCUSceneVariantCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:style reuseIdentifier:reuseIdentifier];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect frame = self.textLabel.frame;
    frame.size.width = CGRectGetWidth(self.frame);
    self.textLabel.frame = frame;
}

@end
