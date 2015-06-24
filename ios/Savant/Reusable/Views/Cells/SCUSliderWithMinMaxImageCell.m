//
//  SCUSceneVolumeCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSliderWithMinMaxImageCell.h"
#import "SCUSlider.h"

@import SDK;

NSString *const SCUSliderMinMaxCellKeyValue = @"SCUSliderMinMaxCellKeyValue";
NSString *const SCUSliderMinMaxCellKeyMinValue = @"SCUSliderMinMaxCellKeyMinValue";
NSString *const SCUSliderMinMaxCellKeyMaxValue = @"SCUSliderMinMaxCellKeyMaxValue";
NSString *const SCUSliderMinMaxCellKeyDelta = @"SCUSliderMinMaxCellKeyDelta";
NSString *const SCUSliderMinMaxCellKeyMinImage = @"SCUSliderMinMaxCellKeyMinImage";
NSString *const SCUSliderMinMaxCellKeyMaxImage = @"SCUSliderMinMaxCellKeyMaxImage";

@interface SCUSliderWithMinMaxImageCell ()

@property SCUSlider *slider;
@property (weak) UIImageView *minImageView, *maxImageView;

@end

@implementation SCUSliderWithMinMaxImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        UIImageView *decreaseImage = [[UIImageView alloc] init];
        decreaseImage.contentMode = UIViewContentModeScaleAspectFit;
        UIImageView *increaseImage = [[UIImageView alloc] init];
        increaseImage.contentMode = UIViewContentModeScaleAspectFit;

        [self.contentView addSubview:decreaseImage];
        [self.contentView sav_pinView:decreaseImage withOptions:SAVViewPinningOptionsVertically];
        self.minImageView = decreaseImage;

        [self.contentView addSubview:increaseImage];
        [self.contentView sav_pinView:increaseImage withOptions:SAVViewPinningOptionsVertically];
        self.maxImageView = increaseImage;

        self.slider = [[SCUSlider alloc] initWithFrame:CGRectZero];
        self.slider.showsIndicator = YES;
        
        [self.contentView addSubview:self.slider];
        [self.contentView sav_pinView:self.slider withOptions:SAVViewPinningOptionsVertically];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"space": @15}
                                                                                  views:@{@"increase": increaseImage,
                                                                                          @"decrease": decreaseImage,
                                                                                          @"slider": self.slider}
                                                                                formats:@[@"|-(space)-[decrease]-(space)-[slider]-(space)-[increase]-(space)-|"]]];

        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    [self.slider setValue:[info[SCUSliderMinMaxCellKeyValue] floatValue] animated:NO];

    NSString *minImageName = info[SCUSliderMinMaxCellKeyMinImage];

    if (minImageName)
    {
        self.minImage = [UIImage imageNamed:minImageName];
    }

    NSString *maxImageName = info[SCUSliderMinMaxCellKeyMaxImage];

    if (maxImageName)
    {
        self.minImage = [UIImage imageNamed:maxImageName];
    }

    NSNumber *minValue = info[SCUSliderMinMaxCellKeyMinValue];

    if (minValue)
    {
        self.slider.minimumValue = [minValue floatValue];
    }

    NSNumber *maxValue = info[SCUSliderMinMaxCellKeyMaxValue];

    if (maxValue)
    {
        self.slider.maximumValue = [maxValue floatValue];
    }

    NSNumber *delta = info[SCUSliderMinMaxCellKeyDelta];

    if (delta)
    {
        self.slider.delta = [delta floatValue];
    }
}

- (void)setMinImage:(UIImage *)minImage
{
    self.minImageView.image = minImage;
}

- (UIImage *)minImage
{
    return self.minImageView.image;
}

- (void)setMaxImage:(UIImage *)maxImage
{
    self.maxImageView.image = maxImage;
}

- (UIImage *)maxImage
{
    return self.maxImageView.image;
}

@end
