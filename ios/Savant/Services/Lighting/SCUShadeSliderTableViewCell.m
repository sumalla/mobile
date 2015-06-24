//
//  SCUShadeSliderTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 2/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUShadeSliderTableViewCell.h"

@interface SCUShadeSliderTableViewCell ()

@property (nonatomic) SCUButton *closeButton;

@property (nonatomic) SCUButton *openButton;

@end

@implementation SCUShadeSliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.minImageView.alpha = 0;
        self.maxImageView.alpha = 0;

        self.closeButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLight image:[UIImage sav_imageNamed:@"ShadesClosed" tintColor:[[SCUColors shared] color04]]];
        self.closeButton.tintImage = NO;
        [self.contentView addSubview:self.closeButton];

        self.openButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLight image:[UIImage sav_imageNamed:@"ShadesOpen" tintColor:[[SCUColors shared] color04]]];
        self.openButton.tintImage = NO;
        [self.contentView addSubview:self.openButton];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.closeButton.frame = self.minImageView.frame;
    self.openButton.frame = self.maxImageView.frame;
}

@end
