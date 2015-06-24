//
//  SCUNotificationAddRuleCell.m
//  SavantController
//
//  Created by Stephen Silber on 1/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationAddRuleCell.h"

@interface SCUNotificationAddRuleCell ()

@end

@implementation SCUNotificationAddRuleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.detailTextLabel.numberOfLines = 0;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect textLabelFrame = self.textLabel.frame;
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    
    CGFloat buffer = 15.0f;
    textLabelFrame.size.width = CGRectGetWidth(self.contentView.frame) * 0.2;
    textLabelFrame.origin.y = CGRectGetMidY(self.contentView.frame) - (CGRectGetHeight(textLabelFrame) / 2);
    
    detailTextLabelFrame.size.width = (CGRectGetWidth(self.contentView.frame) * 0.8) - (buffer * 4.5);
    detailTextLabelFrame.origin.x = CGRectGetMaxX(textLabelFrame) + buffer;
    
    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

@end
