//
//  SCUClimateViewController.h
//  SavantController
//
//  Created by David Fairweather on 5/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewController.h"
#import "SCUClimateServiceModel.h"
#import "SCUHVACPickerView.h"
#import "SCUButton.h"


typedef NS_ENUM(NSInteger, SCUGradientBackgroundColorScheme)
{
    SCUGradientBackgroundColorSchemeIncreaseCurrentClimatePoint,
    SCUGradientBackgroundColorSchemeDecreaseCurrentClimatePoint,
    SCUGradientBackgroundColorSchemeNormal
};

typedef NS_ENUM(NSInteger, SCUClimateSetPointState)
{
    SCUClimateSetPointStateNone,
    SCUClimateSetPointStateInConner,
    SCUClimateSetPointStateArrowViewUp
};

typedef NS_ENUM(NSInteger, SCUClimateValueLabelType)
{
    SCUClimateValueLabelCorner,
    SCUClimateValueLabelCenter,
    SCUClimateValueLabelCenterRangeLow,
    SCUClimateValueLabelCenterRangeHigh,
    SCUClimateValueLabelSetPointPopover
};

@interface SCUClimateViewController : SCUServiceViewController <SCUClimateServiceModelDelegate>

@property (nonatomic, readonly, copy) NSString *turnOnIncreaseCurrentClimatePointText;
@property (nonatomic, readonly, copy) NSString *turnOnDecreaseCurrentClimatePointText;

- (void)animateLabelToCorner:(BOOL)inCorner withTimer:(BOOL)isTimed;
- (void)changeBackgroundColors:(SCUGradientBackgroundColorScheme)scheme;
- (void)turnOffFeedbackTimer;
- (void)setViewColors;
- (void)setupSliderAndPickerViews;
- (void)settingsButtonPressed:(SCUButton *)button;

- (void)initModelWithService:(SAVService *)service;

- (NSString *)setAttributedStringForLabel:(UILabel *)label withValue:(NSInteger)value;

- (BOOL)hasHVACService;

@end
