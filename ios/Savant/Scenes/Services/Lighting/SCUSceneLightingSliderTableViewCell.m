//
//  SCUSceneLightingSlider.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingSliderTableViewCell.h"

@implementation SCUSceneLightingSliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        [self.contentView sav_setWidth:24 forView:self.minImageView isRelative:NO];
        [self.contentView sav_setWidth:24 forView:self.maxImageView isRelative:NO];
        self.slider.callbackTimeInterval = .4;
        self.slider.showsIndicator = NO;
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    self.textLabel.text = nil;
    self.minImage = [UIImage sav_imageNamed:@"BrightnessDown" tintColor:[[SCUColors shared] color03shade08]];
    self.maxImage = [UIImage sav_imageNamed:@"BrightnessUp" tintColor:[[SCUColors shared] color03shade08]];
}

@end
