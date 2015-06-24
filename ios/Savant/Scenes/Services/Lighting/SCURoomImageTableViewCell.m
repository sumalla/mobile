//
//  SCURoomImageTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomImageTableViewCell.h"
#import "SCUGradientView.h"

@interface SCURoomImageTableViewCell ()

@property (nonatomic) UIImageView *roomImage;
@property (nonatomic) UILabel *roomLabel;

@end

@implementation SCURoomImageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.roomImage = [[UIImageView alloc] init];
        self.roomImage.contentMode = UIViewContentModeScaleAspectFill;
        self.roomImage.clipsToBounds = YES;
        [self.contentView addSubview:self.roomImage];
        [self.contentView sav_addFlushConstraintsForView:self.roomImage];
        
        SCUGradientView *gradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03] colorWithAlphaComponent:.8], [[[SCUColors shared] color03] colorWithAlphaComponent:.25]]];
        gradient.locations = @[@(1), @(0)];
        
        [self.contentView addSubview:gradient];
        [self.contentView sav_addFlushConstraintsForView:gradient];
        
        self.roomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.roomLabel.textColor = [[SCUColors shared] color04];
        self.roomLabel.font = [UIDevice isPad] ? [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h6] : [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h7];
        
        [self.contentView addSubview:self.roomLabel];
        [self.contentView sav_pinView:self.roomLabel withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToBottom withSpace:27];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    if (info[SCUDefaultTableViewCellKeyTitle])
    {
        self.roomLabel.text = info[SCUDefaultTableViewCellKeyTitle];
    }
}

@end
