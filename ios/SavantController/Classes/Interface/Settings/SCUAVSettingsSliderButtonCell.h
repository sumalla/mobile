//
//  SCUAVSliderButtonCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUCenteredSlider.h"
#import "SCUButton.h"
#import "SCUSlider.h"

typedef NS_ENUM(NSUInteger, SCUAVSettingsSliderType)
{
    SCUAVSettingsSliderTypeCenter,
    SCUAVSettingsSliderTypeNormal
};

extern NSString *const SCUAVSettingsSliderButtonCellKeyTopTitle;
extern NSString *const SCUAVSettingsSliderButtonCellKeyTopValue;
extern NSString *const SCUAVSettingsSliderButtonCellKeyBottomTitle;
extern NSString *const SCUAVSettingsSliderButtonCellSliderType;
extern NSString *const SCUAVSettingsSliderButtonCellSliderValue;
extern NSString *const SCUAVSettingsSliderCellValueRange;

@interface SCUAVSettingsSliderButtonCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) SCUButton *minusButton;

@property (readonly, nonatomic) SCUButton *addButton;

@property (readonly, nonatomic) SCUButton *bottomButton;

@property (readonly, nonatomic) UILabel *topValueLabel;

@property (readonly, nonatomic) SCUSlider *slider;

@property (readonly, nonatomic) SCUCenteredSlider *centerSlider;

- (void)setSliderValue:(float)value;

- (void)sliderUpdatedValue:(float)value;

@end
