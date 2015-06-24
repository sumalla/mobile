//
//  SCUNotificationInvisibleTableViewCell.m
//  SavantController
//
//  Created by Julian Locke on 1/16/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationInvisibleTableViewCell.h"
#import "SCUNotificationsModel.h"

@implementation SCUNotificationInvisibleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.borderType = SCUDefaultTableViewCellBorderTypeNone;
        self.contentView.borderWidth = 0.0;
        self.borderWidth = 0.0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.frame = self.contentView.frame;
        
        [self.contentView sav_pinView:self.detailTextLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:[[SCUDimens dimens] regular].globalMargin1];
        [self.contentView sav_pinView:self.detailTextLabel withOptions:SAVViewPinningOptionsCenterY];
    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    self.backgroundColor = [UIColor clearColor];
}

@end
